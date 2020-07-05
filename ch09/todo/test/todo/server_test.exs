defmodule Todo.ServerTest do
  use ExUnit.Case, async: true

  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  setup_all do
    Todo.Database.start()

    on_exit(fn ->
      Todo.Database.stop()
    end)

    :ok
  end

  setup do
    Todo.Database.purge_db()
  end

  test "Todo.Server.start() starts a Todo.Server process" do
    assert {:ok, pid} = Todo.Server.start("frank")
    assert is_pid(pid)
  end

  test "Todo.Server.start() starts a new Todo.Server process" do
    {:ok, pid_1} = Todo.Server.start("frank")
    {:ok, pid_2} = Todo.Server.start("frank")
    assert pid_1 != pid_2
  end

  test "Todo.Server.add_entry(pid, entry)" do
    {:ok, pid} = Todo.Server.start("frank")
    assert :ok == Todo.Server.add_entry(pid, @entry)
  end

  test "Todo.Server.entries(pid, date)" do
    {:ok, pid} = Todo.Server.start("frank")
    assert [] == Todo.Server.entries(pid, @entry.date)
    :ok = Todo.Server.add_entry(pid, @entry)
    assert [%{date: ~D[2020-01-01], title: "Dentist"}] = Todo.Server.entries(pid, @entry.date)
  end
end
