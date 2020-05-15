defmodule Todo.CacheTest do
  use ExUnit.Case

  @date ~D[2020-01-01]
  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  setup_all do
    assert {:ok, pid} = Todo.Cache.start()

    on_exit(fn ->
      Database.Server.purge_db()
      Database.Server.stop()
    end)

    %{cache: pid}
  end

  setup %{cache: cache} do
    Database.Server.purge_db()
    Todo.Cache.purge(cache)
    :ok
  end

  test "Todo.Cache.server_process(name) generates new pid for each unique user", %{cache: cache} do
    pid_1 = Todo.Cache.server_process(cache, "test_1")
    assert is_pid(pid_1)
    assert pid_1 == Todo.Cache.server_process(cache, "test_1")

    pid_2 = Todo.Cache.server_process(cache, "test_2")
    assert is_pid(pid_2)
    assert pid_1 != pid_2
  end

  test "Todo.Cache.server_process(name) returns a Todo.Server pid", %{cache: cache} do
    pid_1 = Todo.Cache.server_process(cache, "test_1")

    assert [] == Todo.Server.entries(pid_1, @date)
  end

  test "Todo.Server.add_entry/2 writes to disk", %{cache: cache} do
    pid_1 = Todo.Cache.server_process(cache, "test_1")
    [] = Todo.Server.entries(pid_1, @date)
    :ok = Todo.Server.add_entry(pid_1, @entry)

    # without timer, the database hasn't been written to by the time we check
    :timer.sleep(1)
    assert nil != Database.Server.get("test_1")
  end

  test "Todo.Server.init/2 writes to disk", %{cache: cache} do
    list = Todo.List.new() |> Todo.List.add_entry(@entry)
    :ok = Database.Server.store("test_1", list)

    pid_1 = Todo.Cache.server_process(cache, "test_1")
    assert [@entry] = Todo.Server.entries(pid_1, @date)
  end
end
