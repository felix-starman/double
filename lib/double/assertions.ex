defmodule Double.Assertions do
  import ExUnit.Assertions

  def assert_called({mod, fun, args} = mfargs)
      when is_atom(mod) and is_atom(fun) and is_list(args) do
    with [{agent_pid, _}] <- Registry.lookup(Double.AgentRegistry, self()),
         calls when is_list(calls) <- Double.Agent.calls(agent_pid) do
      from_pids =
        Enum.flat_map(calls, fn
          {from_pid, ^mfargs} -> [from_pid]
          _ -> []
        end)

      # TODO - make this a better error message
      assert length(from_pids) > 0, "no calls made"
    else
      [] -> flunk("No `Double.Agent` has been registered for this test.")
    end

    # find pid of agent
    # 1. check Process dictionary for pid or name
    # if pid, use pid. if name, check Double.AgentRegistry with name
    # 2. check Double.AgentRegistry for agent pid using owner_pid_or_name

    # check Agent process calls
  end

  # defp check_process_dict_for_pid_or_name do
  #   case Process.get(:double_agent) do
  #     nil -> :error
  #     pid when is_pid(pid) -> {:ok, pid: pid}
  #     name when is_tuple(name) and tuple_size(name) == 3 -> {:ok, name: name}
  #   end
  # end
end
