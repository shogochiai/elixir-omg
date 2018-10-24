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

defmodule OMG.API.Application do
  @moduledoc """
  The application here is the Child chain server and its API.
  See here (children) for the processes that compose into the Child Chain server.
  """

  defmodule Loop do
    use OMG.API.LoggerExt
    use GenServer

    def start_link(_args) do
      GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
      send(self(), :tick)
      {:ok, 0}
    end

    def handle_info(:tick, counter) do
      Logger.warn("tick # #{counter}")
      Process.send_after(self(), :tick, 1000)
      {:noreply, counter + 1}
    end
  end

  use Application
  use OMG.API.LoggerExt
  import Supervisor.Spec

  def start(_type, _args) do
    block_finality_margin = Application.get_env(:omg_api, :ethereum_event_block_finality_margin)

    children = [
      {OMG.API.Application.Loop, []},
    ]

    _ = Logger.info(fn -> "Started application OMG.API.Application" end)
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
