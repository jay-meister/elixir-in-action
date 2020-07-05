defmodule TodoCacheTest do
  use ExUnit.Case

  test "server_process" do
    jane_pid = Todo.Cache.server_process("jane")

    assert jane_pid != Todo.Cache.server_process("alice")
    assert jane_pid == Todo.Cache.server_process("jane")
  end

  test "to-do operations" do
    jane = Todo.Cache.server_process("jane")
    Todo.Server.add_entry(jane, %{date: ~D[2018-12-19], title: "Dentist"})
    entries = Todo.Server.entries(jane, ~D[2018-12-19])

    assert [%{date: ~D[2018-12-19], title: "Dentist"}] = entries
  end

  test "persistence", context do
    jane = Todo.Cache.server_process("jane")
    Todo.Server.add_entry(jane, %{date: ~D[2018-12-20], title: "Shopping"})
    assert 1 == length(Todo.Server.entries(jane, ~D[2018-12-20]))

    Process.exit(jane, :kill)

    entries =
      "jane"
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(~D[2018-12-20])

    assert [%{date: ~D[2018-12-20], title: "Shopping"}] = entries
  end
end
