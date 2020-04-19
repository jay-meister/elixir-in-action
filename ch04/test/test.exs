ExUnit.start()

Path.wildcard("#{__DIR__}/../*.ex")
|> Enum.each(fn path ->
  path |> Path.expand() |> Code.compile_file()
end)

defmodule TodoListTest do
  use ExUnit.Case

  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  test "TodoList.new()" do
    assert TodoList.new() == %TodoList{}
  end

  test "TodoList.new(entries)" do
    assert list = %TodoList{} = TodoList.new([@entry, @entry])
    assert list.entries |> Map.keys() |> length() == 2
  end

  test "TodoList.new(csv_path)" do
    path = Path.expand("#{__DIR__}/../todo.csv")
    assert list = %TodoList{} = TodoList.new(path)
    assert list.entries |> Map.keys() |> length() == 3
  end

  test "TodoList.add_entry" do
    list = TodoList.add_entry(TodoList.new(), @entry)

    assert list == %TodoList{auto_id: 2, entries: %{1 => Map.put(@entry, :id, 1)}}

    entry_2 = %{date: ~D[2020-01-01], title: "Clean"}
    list = TodoList.add_entry(list, entry_2)

    assert list == %TodoList{
             auto_id: 3,
             entries: %{
               1 => Map.put(@entry, :id, 1),
               2 => Map.put(entry_2, :id, 2)
             }
           }
  end

  test "TodoList.update_entry" do
    # update empty todo list returns todo list
    list = TodoList.update_entry(TodoList.new(), 1, &Map.put(&1, :date, ~D[2020-01-02]))

    assert list.entries == %{}

    # update entry works if entry exists
    list = TodoList.add_entry(TodoList.new(), @entry)
    updatedList = TodoList.update_entry(list, 1, &Map.put(&1, :date, ~D[2020-01-02]))
    assert updatedList.entries[1].date == ~D[2020-01-02]
  end

  test "TodoList.entries(date)" do
    list = TodoList.new()
    assert TodoList.entries(list, ~D[2020-01-01]) == []
    list = TodoList.add_entry(TodoList.new(), @entry)
    assert TodoList.entries(list, ~D[2020-01-01]) == [Map.put(@entry, :id, 1)]
  end

  test "TodoList.delete(entry_id)" do
    list = TodoList.add_entry(TodoList.new(), @entry)
    assert [entry] = TodoList.entries(list, ~D[2020-01-01])
    list = TodoList.delete_entry(list, entry.id)
    assert [] = TodoList.entries(list, ~D[2020-01-01])
  end
end

defmodule TodoList.CSVImporterTest do
  use ExUnit.Case

  test "TodoList.CSVImporter.import(filename)" do
    path = Path.expand("#{__DIR__}/../todo.csv")

    assert TodoList.CSVImporter.import(path) == [
             %{date: ~D[2018-12-19], title: "Dentist"},
             %{date: ~D[2018-12-20], title: "Shopping"},
             %{date: ~D[2018-12-19], title: "Movies"}
           ]
  end
end
