defmodule Todo.ServerTest do
  use ExUnit.Case, async: true

  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  setup do
    Todo.Database.purge_db()
  end

  test "Todo.Server.add_entry(pid, entry)" do
    {:ok, pid} = Todo.Server.start_link("frank")
    assert :ok == Todo.Server.add_entry(pid, @entry)
  end

  test "Todo.Server.entries(pid, date)" do
    {:ok, pid} = Todo.Server.start_link("frank")
    assert [] == Todo.Server.entries(pid, @entry.date)
    :ok = Todo.Server.add_entry(pid, @entry)
    assert [%{date: ~D[2020-01-01], title: "Dentist"}] = Todo.Server.entries(pid, @entry.date)
  end
end
