defmodule MyShell do

  def local_allowed(_, _, state), do: {false, state}

  def non_local_allowed({:gen, _}, _, state), do: {true, state}
  def non_local_allowed(_, _, state), do: {false, state}

end
