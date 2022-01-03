defmodule Double.AgentRegistry do
  # TODO - incorporate this with the other Registry
  def register(test_pid), do: Registry.register(__MODULE__, test_pid, nil)

  def register(key, value), do: Registry.register(__MODULE__, key, value)

  def lookup(key), do: Registry.lookup(__MODULE__, key)
end
