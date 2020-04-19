defmodule Streams do
  defp stream_lines!(path) do
    File.stream!(path)
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  def large_lines!(path, length) do
    stream_lines!(path)
    |> Enum.filter(&(String.length(&1) > length))
  end

  def lines_lengths!(path) do
    stream_lines!(path)
    |> Enum.map(&String.length/1)
  end

  def longest_line_length!(path) do
    stream_lines!(path)
    |> Stream.map(&String.length/1)
    |> Enum.max()
  end

  def longest_line!(path) do
    stream_lines!(path)
    |> Enum.max_by(&String.length/1)
  end

  def words_per_line!(path) do
    stream_lines!(path)
    |> Stream.map(&length(String.split(&1)))
    |> Enum.map(& &1)
  end
end
