defmodule Double.Stub do
  @moduledoc """
  Records then immediately calls the original source implementation.

  # Important
  The source implementation is called from *within* the Double.Agent process.
  This should not be used from throughput-sensitive code.
  """

  def message(true, source, func_name, args), do: {source, func_name, args}
  def message(false, _source, func_name, []), do: func_name
  def message(false, _source, func_name, args), do: List.to_tuple([func_name | args])

  defmacro __using__(opts) do
    opts = Enum.into(opts, %{})
    source = Map.fetch!(opts, :for)
    send_stubbed_module = Map.get(opts, :send_stubbed_module, false)

    quote location: :keep do
      Module.put_attribute(__MODULE__, :source, unquote(source))
      Module.put_attribute(__MODULE__, :send_stubbed_module, unquote(send_stubbed_module))

      def __handle_double_call__({_stub_mod, func_name, args} = mfargs) do
        double_id = Atom.to_string(__MODULE__)

        message = Double.Stub.message(@send_stubbed_module, @source, func_name, args)
        test_pid = Double.Registry.whereis_test(double_id)
        Kernel.send(test_pid, message)

        pid = Double.Registry.whereis_double(double_id)
        func_list = Double.func_list(pid)
        Double.FuncList.apply(func_list, func_name, args)
      end

      defoverridable(__handle_double_call__: 1)
    end
  end
end
