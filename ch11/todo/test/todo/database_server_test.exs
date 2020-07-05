defmodule Todo.DatabaseTest do
  use ExUnit.Case

  setup do
    Todo.Database.purge_db()
  end

  test "Todo.Database.get(id) returns nil if no file exists" do
    assert nil == Todo.Database.get("test")
  end

  test "Todo.Database.store(id, data)" do
    assert :ok == Todo.Database.store("test", {:some, :data})
    assert {:some, :data} == Todo.Database.get("test")
  end
end
