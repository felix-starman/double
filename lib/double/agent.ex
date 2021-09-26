defmodule Double.Agent do
  use GenServer

  def call({shim_mod, _func_name, _args} = mfargs, _source_mod) do
    # TODO - replace with a Registry lookup, or a via-tuple, starting one if it's not found
    server = {__MODULE__, shim_mod}

    GenServer.call(server, mfargs)
  end

  def child_spec(shim_mod) do
    %{
      id: {__MODULE__, shim_mod},
      start: {__MODULE__, :start_link, [shim_mod]},
      restart: :transient
    }
  end

  def start_link({shim_mod, source_mod}) do
    # TODO - replace with a Registry via-tuple, or something
    GenServer.start_link(__MODULE__, {shim_mod, source_mod}, name: {__MODULE__, shim_mod})
  end

  def init({shim_mod, source_mod}) do
    state = %{
      source: source_mod,
      name: shim_mod
    }

    {:ok, state}
  end

  def handle_call({_mod, func_name, args} = mfargs, from, %{source: source} = state) do
    # TODO - resume here
    Double.Listener.record(mfargs, from)
    result = apply(source, func_name, args)

    {:reply, result, state}
  end
end
