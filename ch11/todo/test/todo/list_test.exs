defmodule Todo.ListTest do
  use ExUnit.Case, async: true

  @date ~D[2020-01-01]
  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  test "Todo.List.new()" do
    assert Todo.List.new() == %Todo.List{}
  end

  test "Todo.List.new(entries)" do
    assert list = %Todo.List{} = Todo.List.new([@entry, @entry])
    assert list.entries |> Map.keys() |> length() == 2
  end

  test "Todo.List.add_entry" do
    list = Todo.List.add_entry(Todo.List.new(), @entry)

    assert list == %Todo.List{
             auto_id: 2,
             entries: %{
               1 => Map.put(@entry, :id, 1)
             }
           }

    entry_2 = %{date: @date, title: "Clean"}
    list = Todo.List.add_entry(list, entry_2)

    assert list == %Todo.List{
             auto_id: 3,
             entries: %{
               1 => Map.put(@entry, :id, 1),
               2 => Map.put(entry_2, :id, 2)
             }
           }
  end

  test "Todo.List.update_entry" do
    # update empty todo list returns todo list
    list = Todo.List.update_entry(Todo.List.new(), 1, &Map.put(&1, :date, ~D[2020-01-02]))

    assert list.entries == %{}

    # update entry works if entry exists
    list = Todo.List.add_entry(Todo.List.new(), @entry)
    updatedList = Todo.List.update_entry(list, 1, &Map.put(&1, :date, ~D[2020-01-02]))
    assert updatedList.entries[1].date == ~D[2020-01-02]
  end

  test "Todo.List.entries(date)" do
    list = Todo.List.new()
    assert Todo.List.entries(list, @date) == []
    list = Todo.List.add_entry(Todo.List.new(), @entry)
    assert Todo.List.entries(list, @date) == [Map.put(@entry, :id, 1)]
  end

  test "Todo.List.delete(entry_id)" do
    list = Todo.List.add_entry(Todo.List.new(), @entry)
    assert [entry] = Todo.List.entries(list, @date)
    list = Todo.List.delete_entry(list, entry.id)
    assert [] = Todo.List.entries(list, @date)
  end
end
