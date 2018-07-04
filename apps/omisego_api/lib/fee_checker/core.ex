defmodule OmiseGO.API.FeeChecker.Core do
  @moduledoc """
  Transaction's fee validation functions
  """

  alias OmiseGO.API.State.Transaction
  alias OmiseGO.API.State.Transaction.Recovered

  @doc """
  Calculates fee from tx and checks whether token is allowed and both percentage and flat fee limits are met
  """
  @spec transaction_fees(Recovered.t(), list()) ::
          {:ok, map()} | {:error, :token_not_allowed}
  def transaction_fees(recovered_tx, token_fees) do
    with %Recovered{raw_tx: %Transaction{amount1: amount1, amount2: amount2, cur12: currency}} <- recovered_tx,
      {:ok, fee} <- get_fee_for_token(token_fees, currency) do

      {:ok, %{currency => amount1 + amount2 + fee}}
    end
  end

  @spec get_fee_for_token(list(map()), Crypto.address_t()) :: {:ok, pos_integer} | {:error, :token_not_allowed}
  defp get_fee_for_token(token_fees, currency) do
    token_fees
    |> Enum.find(fn (%{token: token}) -> token == currency end)
    |> extract_fee()
  end

  defp extract_fee(%{token: token, flat_fee: flat_fee}), do: {:ok, flat_fee}
  defp extract_fee(nil), do: {:error, :token_not_allowed}
end
