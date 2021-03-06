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

defmodule OMG.RPC.Web.Controller.FallbackTest do
  use ExUnitFixtures
  use ExUnit.Case, async: false

  alias OMG.RPC.Web.TestHelper

  @tag fixtures: [:phoenix_sandbox]
  test "invalid user input without validation is handled as unknown error" do
    invalid_input = %{hash: "not-hex-string"}

    assert %{
             "success" => false,
             "version" => "1.0",
             "data" => %{
               "object" => "error",
               "code" => "get_block::unknown_error",
               "description" => nil
             }
           } == TestHelper.rpc_call(:post, "/block.get", invalid_input)
  end
end
