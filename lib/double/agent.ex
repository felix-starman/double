defmodule Double.Agent do
  use GenServer

  defmodule NotFoundError do
    defexception [:message]

    @impl true
    def exception(value) do
      msg = """
      No `Double.Agent` was found to be associated to this process:

                  pid: #{inspect(self())}
                  call: #{inspect(value)}
      """

      %__MODULE__{message: msg}
    end
  end

  # TODO - remove all this, or incorporate it with the Double GenServer.
  # Or call it the Listener again, idk.

  def register_test(agent_pid, test_pid) do
    GenServer.call(agent_pid, {:register, test_pid})
  end

  def record({_shim_mod, _func_name, _args} = mfargs, opts \\ []) do
    case Double.AgentRegistry.lookup(self()) do
      [{pid, _}] -> pid
      [] -> raise(NotFoundError, mfargs)
    end
    |> GenServer.call({:record, mfargs, opts})
  end

  def calls(pid) when is_pid(pid) do
    GenServer.call(pid, :list_calls)
  end

  def calls(test_meta) do
    test_meta
    |> name_via_registry()
    |> GenServer.call(:list_calls)
  end

  def child_spec(%{module: test_mod, describe: desc_str, test: test_str}) do
    test_info = {test_mod, desc_str, test_str}

    %{
      id: {__MODULE__, test_info},
      start: {__MODULE__, :start_link, [test_info]},
      restart: :transient
    }
  end

  def name_via_registry(%{module: test_mod, describe: desc_str, test: test_str}) do
    test_info = {test_mod, desc_str, test_str}
    {:via, Registry, {Double.AgentRegistry, test_info}}
  end

  def name_via_registry(key) do
    {:via, Registry, {Double.AgentRegistry, key}}
  end

  def start_link({_test_mod, _desc_str, _test_str} = test_info) do
    GenServer.start_link(__MODULE__, test_info, name: name_via_registry(test_info))
  end

  def init(name) do
    {:ok, %{name: name, calls: []}}
  end

  def handle_call({:register, test_pid}, _from, state) do
    {:reply, Double.AgentRegistry.register(test_pid), state}
  end

  def handle_call({:record, mfargs, opts}, {from_pid, _tag}, %{calls: calls} = state) do
    new_state = %{state | calls: [{from_pid, mfargs} | calls]}

    if opts[:call_source] do
      # TODO - remove this, it's a bad idea. calling the original should happen from the calling process
      {:reply, :ok, new_state, {:continue, {:call_source, mfargs}}}
    else
      {:reply, :ok, new_state}
    end
  end

  def handle_continue({:call_source, _mfargs}, state) do
    {:noreply, state}
  end

  def handle_call(
        {_mod, func_name, args} = mfargs,
        {from_pid, _tag},
        %{source: source, calls: calls} = state
      ) do
    # Double.Listener.record(mfargs, from)
    result = apply(source, func_name, args)

    {:reply, result, %{state | calls: [{from_pid, mfargs} | calls]}}
  end

  def handle_call(:list_calls, _from, state) do
    {:reply, state.calls, state}
  end
end
