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

defmodule OMG.Watcher.ExitProcessor.InFlightExitInfo do
  @moduledoc """
  Represents the bulk of information about a tracked in-flight exit.

  Internal stuff of `OMG.Watcher.ExitProcessor`
  """

  alias OMG.API.Utxo;

  # mapped by :in_flight_exit_id
  defstruct [
    :tx,
    :timestamp,
    :priority,
    # piggybacking
    exit_map: <<0,0>>,
    tx_pos: nil,
    oldest_competitor: 0,
    is_canonical: true
  ]

  @type t :: %__MODULE__{
          tx: Transaction.Signed.t(),
          tx_pos: nil | Utxo.Position.t(),
          timestamp: pos_integer(),
          priority: non_neg_integer(),
          exit_map: <<_::16>>,
          oldest_competitor: non_neg_integer(),
          is_canonical: boolean()
        }

  def get_exit_id_from_tx_hash(tx_hash) when is_binary(tx_hash) and byte_size(tx_hash) == 32 do
    # cut the oldest 8 bytes and shift left by one bit (least significant bit is set to 0)
    <<_::65, ife_id::bitstring-size(192)>> = <<tx_hash::bitstring, <<0::1>>::bitstring>>
    ife_id
  end

  def get_exiting_utxo_pos(ife = %__MODULE__{is_canonical: false}) do
    ife.inputs
    |> Enum.with_index()
    |> Enum.filter(&(is_active(ife, :input, elem(&1, 1))))
    |> Enum.map(&(&1 |> elem(0) |> elem(0)))
  end
  def get_exiting_utxo_pos(ife = %__MODULE__{is_canonical: true, tx_pos: tx_pos}) when tx_pos != nil do
    active_outputs_offsets =
      ife.outputs
      |> Enum.with_index()
      |> Enum.filter(&(is_active(ife, :input, elem(&1, 1))))
      |> Enum.map(&(&1 |> elem(1)))
    {:utxo_position, blknum, txindex, _} = tx_pos
    for pos <- active_outputs_offsets, do: {:utxo_position, blknum, txindex, pos}
  end
  def get_exiting_utxo_pos(_) do
    []
  end

  def is_piggybacked(%__MODULE__{exit_map: bitmap}, type, index) do
    read_bit(bitmap, index + offset(type)) == 1
  end

  def is_finalized(%__MODULE__{exit_map: bitmap}, type, index) do
    read_bit(bitmap, 8 + index + offset(type)) == 1
  end

  def is_active(ife, type, index) do
    is_piggybacked(ife, type, index) and not is_finalized(ife, type, index)
  end

  defp offset(:input), do: 0
  defp offset(:output), do: 4

  defp read_bit(bitmap, index) do
    prefix = 15 - index
    <<_::bits-size(prefix), bit::integer-size(1), _::bits>> = bitmap
    bit
  end
end
