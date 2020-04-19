defmodule R do
  #
  # List Length
  def list_len([]), do: 0
  def list_len([_h | t]), do: 1 + list_len(t)

  #
  # Range

  def range(from, to) when from > to, do: []

  def range(from, to) do
    [from | range(from + 1, to)]
  end

  #
  # Positive

  def positive([]), do: []

  def positive([h | t]) do
    if h > 0 do
      [h | positive(t)]
    else
      positive(t)
    end
  end
end

defmodule RTail do
  #
  # List Length
  def list_len(list), do: list_len(0, list)
  def list_len(count, []), do: count
  def list_len(count, [_h | t]), do: list_len(count + 1, t)

  #
  # Range
  def range(from, to) when from < to do
    loop([], from, to)
    |> Enum.reverse()
  end

  def loop(list, from, to) when from > to, do: list

  def loop(list, from, to) do
    loop([from | list], from + 1, to)
  end

  #
  # Positive
  def positive(list) do
    positive([], list)
  end

  def positive(acc, []), do: acc |> Enum.reverse()

  def positive(acc, [h | t]) do
    if h > 0 do
      positive([h | acc], t)
    else
      positive(acc, t)
    end
  end
end
