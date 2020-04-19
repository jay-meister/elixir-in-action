defmodule CalcServer do
  # api
  def start() do
    spawn(fn -> loop(0) end)
  end

  def value(calc_server_pid) do
    send(calc_server_pid, {:get_value, self()})

    receive do
      {:curr_state, state} -> state
    end
  end

  def add(calc_server_pid, val) do
    send(calc_server_pid, {:operation, :add, val})
    calc_server_pid
  end

  def sub(calc_server_pid, val) do
    send(calc_server_pid, {:operation, :sub, val})
    calc_server_pid
  end

  def mul(calc_server_pid, val) do
    send(calc_server_pid, {:operation, :mul, val})
    calc_server_pid
  end

  def div(calc_server_pid, val) do
    send(calc_server_pid, {:operation, :div, val})
    calc_server_pid
  end

  # server implementation
  defp loop(state) do
    new_state =
      receive do
        {:get_value, caller} ->
          send(caller, {:curr_state, state})
          state

        {:operation, op, val} ->
          case op do
            :add -> state + val
            :sub -> state - val
            :mul -> state * val
            :div -> state / val
          end
      end

    loop(new_state)
  end
end
