defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}

  def new() do
    %Todo.List{}
  end

  def new(entries) when is_list(entries) do
    Enum.reduce(entries, %Todo.List{}, fn entry, acc -> add_entry(acc, entry) end)
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
