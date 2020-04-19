defmodule TodoServer do
  Code.compile_file("#{__DIR__}/../ch04/simple_todo.ex")

  # api
  def start() do
    spawn(fn -> loop(TodoList.new()) end)
  end

  def entries(server_pid, date) do
    send(server_pid, {:get_entries, self(), date})

    receive do
      {:entries, entries} -> entries
    end
  end

  def add_entry(server_pid, entry) do
    send(server_pid, {:add_entry, entry})
    server_pid
  end

  # implementation
  def loop(todo_list) do
    todo_list =
      receive do
        {:get_entries, caller, date} ->
          send(caller, {:entries, TodoList.entries(todo_list, date)})
          todo_list

        {:add_entry, entry} ->
          TodoList.add_entry(todo_list, entry)
      end

    loop(todo_list)
  end
end
