defmodule Todo.CacheTest do
  use ExUnit.Case

  alias Todo.Cache

  @date ~D[2020-01-01]
  @entry %{date: ~D[2020-01-01], title: "Gardening"}

  describe "Todo.Cache" do
    test "starts with empty map" do
      assert :ok = Cache.start()
    end

    test "server_process starts Todo.Server process if new name" do
      :ok = Cache.start()

      assert frank_pid = Cache.server_process(:frank)
      assert is_pid(frank_pid)
      assert frank_pid == Cache.server_process(:frank)
      assert frank_pid != Cache.server_process(:sally)
    end

    test "server_process if no registered name" do
      :ok = Cache.start()

      assert [] = Cache.server_process(:frank) |> Todo.Server.entries(@date)
      :ok = Cache.server_process(:frank) |> Todo.Server.add_entry(@entry)
      assert [@entry] = Cache.server_process(:frank) |> Todo.Server.entries(@date)
    end
  end
end
