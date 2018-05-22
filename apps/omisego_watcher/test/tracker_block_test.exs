defmodule OmiseGOWatcher.TrackerOmisegoTest do
  use ExUnitFixtures
  use ExUnit.Case, async: false

  use Plug.Test

  alias OmiseGO.Eth
  alias OmiseGO.API.State.Transaction

  def jsonrpc(method, params) do
    jsonrpc_port = Application.get_env(:omisego_jsonrpc, :omisego_api_rpc_port)

    "http://localhost:#{jsonrpc_port}"
    |> JSONRPC2.Clients.HTTP.call(to_string(method), params)
  end

  defp deposit_to_child_chain(to, value, config) do
    {:ok, destiny_enc} = Eth.DevHelpers.import_unlock_fund(to)
    {:ok, deposit_tx_hash} = Eth.DevHelpers.deposit(value, 0, destiny_enc, config.contract.address)
    {:ok, receipt} = Eth.WaitFor.eth_receipt(deposit_tx_hash)
    deposit_height = Eth.DevHelpers.deposit_height_from_receipt(receipt)

    post_deposit_child_block =
      deposit_height - 1 + (config.ethereum_event_block_finality_margin + 5) * config.child_block_interval

    {:ok, _} =
      Eth.DevHelpers.wait_for_current_child_block(post_deposit_child_block, true, 60_000, config.contract.address)

    deposit_height
  end

  @tag fixtures: [:watcher, :config_map, :geth, :child_chain, :alice, :bob]
  test "run_omisego_api", %{config_map: config_map, alice: alice, bob: bob} do
    Application.put_env(:omisego_watcher, OmiseGOWatcher.TrackerOmisego, %{
      contract_address: config_map.contract.address
    })

    {:ok, _pid} = GenServer.start_link(OmiseGOWatcher.TrackerOmisego, %{contract_address: config_map.contract.address})

    deposit_height = deposit_to_child_chain(alice, 10, config_map)
    raw_tx = Transaction.new([{deposit_height, 0, 0}], [{alice.addr, 7}, {bob.addr, 3}], 0)
    tx = raw_tx |> Transaction.sign(alice.priv, <<>>) |> Transaction.Signed.encode()
    {:ok, %{"blknum" => block_nr}} = jsonrpc(:submit, %{transaction: Base.encode16(tx)})

    Eth.DevHelpers.wait_for_current_child_block(
      block_nr + 5 * config_map.child_block_interval,
      true,
      60_000,
      config_map.contract.address
    )

    [%{"amount" => amout_bob}] = get_utxo(bob)
    [%{"amount" => amout_alice}] = get_utxo(alice)
    assert amout_bob == 3
    assert amout_alice == 7
  end

  defp get_utxo(from) do
    response =
      :get
      |> conn("account/utxo?address=#{OmiseGO.JSONRPC.Helper.encode(from.addr)}")
      |> put_private(:plug_skip_csrf_protection, true)
      |> OmiseGOWatcherWeb.Endpoint.call([])

    Poison.decode!(response.resp_body)["utxos"]
  end
end