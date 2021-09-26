defmodule Double.Shim do
  defmacro __using__(for: source) do
    quote do
      def __handle_shim_call__({shim_mod, func_name, args} = mfargs) do
        Double.Agent.call(mfargs, unquote(source))
      end

      defoverridable(__handle_shim_call__: 1)
    end
  end
end
