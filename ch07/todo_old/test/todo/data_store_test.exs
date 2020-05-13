defmodule DataStoreTest do
  use ExUnit.Case

  test "DataStore" do
    DataStore.Server.start()
    assert :ok = DataStore.Server.store("test", %{a: :map})
    assert %{a: :map} == DataStore.Server.get("test")
  end
end
