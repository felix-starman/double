defmodule Inspector do
  # TODO - decide what to do with this
  defmacro __before_compile__(env) do
    wrapped_mod = Macro.expand(env.module, env)
    functions_with_arities = Module.definitions_in(env.module)

    func_defs =
      for {func_name, arity} <- functions_with_arities do
        args = Macro.generate_arguments(arity, wrapped_mod)

        quote do
          def unquote(func_name)(unquote_splicing(args)) do
            Double.Agent.record(
              {unquote(wrapped_mod), unquote(func_name), [unquote_splicing(args)]}
            )

            super(unquote_splicing(args))
          end
        end
      end

    quote do
      defoverridable(unquote(functions_with_arities))

      unquote(func_defs)
    end
  end
end

defmodule Custom do
  # TODO - make a __before_compile__ for a Mock or Spy or something
  @before_compile Inspector

  def io_puts(x), do: x
  def sleep(x), do: x
  def process, do: nil
  def process(x), do: x
  def process(x, y, z), do: {x, y, z}
  def another_function, do: nil
  def another_function(x), do: x
  def send(a, b), do: {a, b}
end

defmodule AgentTest do
  use ExUnit.Case, async: false

  test "tracks invocations with an agent", meta do
    # TODO - turn some of these things into setup/on_exit hooks

    start_supervised!({Registry, keys: :unique, name: Double.AgentRegistry})
    agent_pid = start_supervised!({Double.Agent, meta})
    test_pid = self()

    Double.Agent.register_test(agent_pid, test_pid)

    assert :abc = Custom.process(:abc)

    expected_calls = [{test_pid, {Custom, :process, [:abc]}}]
    # can be checked with an explicit pid of the Double.Agent
    assert ^expected_calls = Double.Agent.calls(agent_pid)

    # can be checked with the module that was inspected
    assert ^expected_calls = Double.Agent.calls(meta)

    # can be checked with the expected mfargs of the function for the inspected module
    Double.assert_called({Custom, :process, [:abc]})

    # fails when you try to call it from an unregistered process
    Task.async(fn ->
      assert_raise(Double.Agent.NotFoundError, fn ->
        Custom.process(:bad_child)
      end)
    end)
    |> Task.await()

    # passes when you call it from a registered process
    Task.async(fn ->
      Double.Agent.register_test(agent_pid, self())
      Custom.process(:good_child)
    end)
    |> Task.await()
  end
end
