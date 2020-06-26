defmodule Todo.CacheTest do
  use ExUnit.Case

  @date ~D[2020-01-01]
  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  setup do
    Todo.Database.purge_db()
    :ok
  end

  test "Todo.Cache.server_process(name) generates new pid for each unique user" do
    pid_1 = Todo.Cache.server_process("test_1")
    assert is_pid(pid_1)
    assert pid_1 == Todo.Cache.server_process("test_1")

    pid_2 = Todo.Cache.server_process("test_2")
    assert is_pid(pid_2)
    assert pid_1 != pid_2
  end

  test "Todo.Cache.server_process(name) returns a Todo.Server pid" do
    pid_1 = Todo.Cache.server_process("test_2")

    assert [] == Todo.Server.entries(pid_1, @date)
  end

  test "Todo.Server.add_entry/2 writes to disk" do
    pid_1 = Todo.Cache.server_process("test_3")
    [] = Todo.Server.entries(pid_1, @date)
    :ok = Todo.Server.add_entry(pid_1, @entry)

    # without timer, the database hasn't been written to by the time we check
    :timer.sleep(1)
    assert nil != Todo.Database.get("test_3")
  end

  test "Todo.Server.init/2 writes to disk" do
    list = Todo.List.new() |> Todo.List.add_entry(@entry)
    :ok = Todo.Database.store("test_4", list)

    pid_1 = Todo.Cache.server_process("test_4")
    assert [@entry] = Todo.Server.entries(pid_1, @date)
  end
end
