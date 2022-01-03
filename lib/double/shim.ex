defmodule Double.Shim do
  @moduledoc """
  Records then immediately calls the original source implementation.

  # Important
  The source implementation is called from *within* the Double.Agent process.
  This should not be used from throughput-sensitive code.
  """

  defmacro __using__(for: source) do
    quote do
      def __handle_double_call__({shim_mod, func_name, args} = mfargs) do
        # TODO - determine if there's a better name for this
        # opts controlling behaviour like this feels weird
        Double.Agent.record(mfargs, call_source: true)
      end

      defoverridable(__handle_double_call__: 1)
    end
  end
end
