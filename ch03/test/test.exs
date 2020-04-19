# run: elixir test.exs
ExUnit.start()

defmodule StreamsTest do
  use ExUnit.Case

  @file_path "#{__DIR__}/file.txt"

  describe "Streams" do
    Code.compile_file("#{__DIR__}/../streams.ex")

    test "Streams.large_lines!/2" do
      assert Streams.large_lines!(@file_path, 0) == ["doo", "doo daa", "doo daa dee"]
      assert Streams.large_lines!(@file_path, 3) == ["doo daa", "doo daa dee"]
      assert Streams.large_lines!(@file_path, 7) == ["doo daa dee"]
    end

    test "Streams.lines_lengths!/1" do
      assert Streams.lines_lengths!(@file_path) == [3, 7, 11]
    end

    test "Streams.longest_line_length!/1" do
      assert Streams.longest_line_length!(@file_path) == String.length("doo daa dee")
    end

    test "Streams.longest_line!/1" do
      assert Streams.longest_line!(@file_path) == "doo daa dee"
    end

    test "Streams.words_per_line!/1" do
      assert Streams.words_per_line!(@file_path) == [1, 2, 3]
    end
  end
end
