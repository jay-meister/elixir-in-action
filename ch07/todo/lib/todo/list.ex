defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}

  def new() do
    %Todo.List{}
  end

  def new(entries) when is_list(entries) do
    Enum.reduce(entries, %Todo.List{}, fn entry, acc -> add_entry(acc, entry) end)
  end

  def new(path) when is_binary(path) do
    Todo.List.CSVImporter.import(path)
    |> new()
  end

  def add_entry(list, entry) do
    entry_id = list.auto_id

    entry = Map.put(entry, :id, entry_id)

    list
    |> Map.put(:auto_id, entry_id + 1)
    |> Map.update!(:entries, &Map.put(&1, entry_id, entry))
  end

  def update_entry(%Todo.List{entries: entries} = list, id, fun) when is_map_key(entries, id) do
    Map.update!(list, :entries, &Map.update!(&1, id, fun))
  end

  def update_entry(list, _id, _fun) do
    list
  end

  def delete_entry(list, id) when is_integer(id) do
    %Todo.List{list | entries: Map.delete(list.entries, id)}
  end

  def entries(list, date) do
    list.entries
    |> Stream.filter(fn {_id, entry} -> entry.date == date end)
    |> Enum.map(&elem(&1, 1))
  end
end

defimpl Collectable, for: Todo.List do
  def into(original) do
    into_callback = fn
      list, {:cont, entry} -> Todo.List.add_entry(list, entry)
      list, :done -> list
      _list, :halt -> :ok
    end

    {original, into_callback}
  end
end

defimpl String.Chars, for: Todo.List do
  def to_string(%Todo.List{} = list) do
    list.entries
    |> Enum.map(fn {_id, entry} -> entry end)
    |> Enum.group_by(fn entry -> entry.date end)
    |> Enum.map(fn {date, entries} ->
      "#{Date.to_string(date)}: #{Enum.map(entries, & &1.title) |> Enum.join(", ")}"
    end)
    |> Enum.join("\n")
  end
end

defmodule Todo.List.CSVImporter do
  def import(path) do
    File.stream!(path)
    |> Stream.map(&String.replace(&1, "\n", ""))
    |> Stream.map(&String.split(&1, ","))
    |> Enum.map(&build_entry/1)
  end

  defp build_entry([date, title]) do
    date = date |> String.replace("/", "-") |> Date.from_iso8601!()
    %{date: date, title: title}
  end
end
