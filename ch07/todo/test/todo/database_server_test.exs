defmodule Database.ServerTest do
  use ExUnit.Case

  setup_all do
    {:ok, _pid} = Database.Server.start()

    on_exit(fn ->
      Database.Server.purge_db()
      Database.Server.stop()
    end)

    :ok
  end

  setup do
    Database.Server.purge_db()
  end

  test "Database.Server.get(id) returns nil if no file exists" do
    assert nil == Database.Server.get("test")
  end

  test "Database.Server.store(id, data)" do
    assert :ok == Database.Server.store("test", {:some, :data})
    assert {:some, :data} == Database.Server.get("test")
  end
end
