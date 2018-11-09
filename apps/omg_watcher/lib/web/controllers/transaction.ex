# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule OMG.Watcher.Web.Controller.Transaction do
  @moduledoc """
  Operations related to transaction.
  """

  use OMG.Watcher.Web, :controller
  use PhoenixSwagger

  alias OMG.API.Crypto
  alias OMG.API.State
  alias OMG.Watcher.DB
  alias OMG.Watcher.Web.View

  import OMG.Watcher.Web.ErrorHandler

  @default_transactions_limit 200

  @doc """
  Retrieves a specific transaction by id.
  """
  def get_transaction(conn, %{"id" => id}) do
    id
    |> Base.decode16!()
    |> DB.Transaction.get(true)
    |> respond(conn)
  end

  @doc """
  Retrieves a list of transactions
  """
  def get_transactions(conn, params) do
    address = Map.get(params, "address")
    limit = Map.get(params, "limit", @default_transactions_limit)
    {limit, ""} = limit |> Kernel.to_string() |> Integer.parse()

    # TODO: implement pagination. Defend against fetching huge dataset.
    limit = min(limit, @default_transactions_limit)

    transactions =
      if address == nil do
        DB.Transaction.get_last(limit)
      else
        {:ok, address_decode} = Crypto.decode_address(address)
        DB.Transaction.get_by_address(address_decode, limit)
      end

    respond_multiple(transactions, conn)
  end

  @doc """
  Produces hex-encoded transaction bytes for provided inputs and outputs.

  This is a convenience endpoint used by wallets. User's utxos and new outputs are provided to the endpoint.
  The endpoint responds with transaction bytes that wallet uses to sign with user's keys. Then signed transaction
  is submitted directly to plasma chain.
  """
  def encode_transaction(conn, body) do
    with {inputs, outputs} <- parse_request_body(body),
         # TODO: Transaction's fees are not supported yet
         fee <- 0,
         {:ok, transaction} <- State.Transaction.create_from_utxos(inputs, outputs, fee) do
      transaction
    end
    |> respond(conn)
  end

  defp respond_multiple(transactions, conn),
    do: render(conn, View.Transaction, :transactions, transactions: transactions)

  defp respond(%DB.Transaction{} = transaction, conn),
    do: render(conn, View.Transaction, :transaction, transaction: transaction)

  defp respond(nil, conn), do: handle_error(conn, :transaction_not_found)

  defp respond(%State.Transaction{} = transaction, conn),
    do: render(conn, View.Transaction, :transaction_encode, transaction: transaction)

  defp respond({:error, code}, conn) when is_atom(code), do: handle_error(conn, code)

  defp parse_request_body(%{"inputs" => inputs, "outputs" => outputs}) when is_list(inputs) and is_list(outputs) do
    {
      inputs
      |> Enum.map(&Map.delete(&1, "txbytes"))
      |> Enum.map(fn %{} = input ->
        input = input |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
        %{input | currency: Base.decode16!(input.currency, case: :mixed)}
      end),
      outputs
      |> Enum.map(fn %{} = output ->
        output = output |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
        %{output | owner: OMG.API.Crypto.decode_address!(output.owner)}
      end)
    }
  end

  def swagger_definitions do
    %{
      Transaction:
        swagger_schema do
          title("Transaction")

          properties do
            txhash(:string, "Transaction hash", required: true)
            txindex(:integer, "Transaction index", required: true)
            block(Schema.ref(:Block), "Plasma block the transaction was included in")
            inputs(Schema.ref(:Utxos), "Transaction inputs")
            outputs(Schema.ref(:Utxos), "Transaction outputs")
          end

          example(%{
            txhash: "5DF13A6BF96DBCF6E66D8BABD6B55BD40D64D4320C3B115364C6588FC18C2A21",
            txindex: 1,
            block: %{
              hash: "0017372421F9A92BEDB7163310918E623557AB5310BEFC14E67212B660C33BEC",
              blknum: 68_290_000,
              timestamp: 1_540_365_586,
              eth_height: 97_424
            },
            inputs: [
              %{
                currency: "0000000000000000000000000000000000000000",
                amount: 10,
                owner: "B3256026863EB6AE5B06FA396AB09069784EA8EA",
                blknum: 1000,
                txindex: 1,
                oindex: 0
              }
            ],
            outputs: [
              %{
                currency: "0000000000000000000000000000000000000000",
                amount: 2,
                owner: "B3256026863EB6AE5B06FA396AB09069784EA8EA",
                blknum: 3000,
                txindex: 1,
                oindex: 0
              },
              %{
                currency: "0000000000000000000000000000000000000000",
                amount: 7,
                owner: "AE8AE48796090BA693AF60B5EA6BE3686206523B",
                blknum: 1000,
                txindex: 1,
                oindex: 1
              }
            ]
          })
        end,
      TransactionItem:
        swagger_schema do
          title("Transaction item of a list")

          properties do
            txhash(:string, "Transaction hash", required: true)
            blknum(:integer, "Number of block in Plasma Chain this transaction was included in", required: true)
            txindex(:integer, "Transaction index", required: true)
            eth_height(:integer, "Number of a Ethereum block this block was mined", required: true)
            timestamp(:integer, "Timestamp of a Ethereum block this block was mined", required: true)
          end

          example(%{
            txhash: "5DF13A6BF96DBCF6E66D8BABD6B55BD40D64D4320C3B115364C6588FC18C2A21",
            blknum: 68_290_000,
            txindex: 12_345,
            timestamp: 1_540_365_586,
            eth_height: 97_424
          })
        end,
      Transactions:
        swagger_schema do
          title("Array of transactions")
          type(:array)
          items(Schema.ref(:TransactionItem))
        end,
      Block:
        swagger_schema do
          title("Block")

          properties do
            hash(:string, "Block hash", required: true)
            blknum(:integer, "Number of block in Plasma Chain", required: true)
            eth_height(:integer, "Number of a Ethereum block this block was mined", required: true)
            timestamp(:integer, "Timestamp of a Ethereum block this block was mined", required: true)
          end

          example(%{
            hash: "0017372421F9A92BEDB7163310918E623557AB5310BEFC14E67212B660C33BEC",
            blknum: 68_290_000,
            timestamp: 1_540_365_586,
            eth_height: 97_424
          })
        end,
      Output:
        swagger_schema do
          title("Output")

          properties do
            amount(:integer, "Amount of the currency. Currency is derived from inputs.", required: true)
            owner(:string, "Address of output's owner", required: true)
          end

          example(%{
            "amount" => 97,
            "owner" => "B3256026863EB6AE5B06FA396AB09069784EA8EA"
          })
        end,
      Outputs:
        swagger_schema do
          title("Array of outputs")
          type(:array)
          items(Schema.ref(:Output))
        end,
      PostTransaction:
        swagger_schema do
          title("Inputs and outputs to transaction")

          properties do
            inputs(Schema.ref(:Utxos), "Array of utxos to spend", required: true)
            outputs(Schema.ref(:Outputs), "Array of new owners and amounts", required: true)
          end
        end
    }
  end

  swagger_path :get_transaction do
    get("/transaction")
    summary("Gets a transaction with the given id")

    parameters do
      id(:path, :string, "Id of the transaction", required: true)
    end

    response(200, "OK", Schema.ref(:Transaction))
  end

  swagger_path :get_transactions do
    get("/transactions")
    summary("Gets a list of transactions.")

    parameters do
      address(:query, :string, "Address of the sender or recipient", required: false)
      limit(:query, :integer, "Limits number of transactions. Default value is 200", required: false)
    end

    response(200, "OK", Schema.ref(:Transactions))
  end

  swagger_path :encode_transaction do
    post("/transaction")
    summary("Produces hex-encoded transaction bytes for provided inputs and outputs.")

    parameters do
      body(:body, Schema.ref(:PostTransaction), "The request body", required: true)
    end

    response(200, "OK")
  end
end
