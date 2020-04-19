ExUnit.start()

Path.wildcard("#{__DIR__}/../*.ex")
|> Enum.each(fn path ->
  path |> Path.expand() |> Code.compile_file()
end)

defmodule TodoServerTest do
  use ExUnit.Case

  @entry %{date: ~D[2020-01-01], title: "Dentist"}

  test "TodoServer.start() returns pid" do
    pid = TodoServer.start()
    assert is_pid(pid)
  end

  test "TodoServer.entries(pid, date) lists entries" do
    pid = TodoServer.start()

    assert [] == TodoServer.entries(pid, ~D[2020-01-01])
  end

  test "TodoServer.add_entry(pid, entry) adds entry" do
    pid = TodoServer.start()

    TodoServer.add_entry(pid, @entry)

    assert [%{id: 1, date: ~D[2020-01-01], title: "Dentist"}] ==
             TodoServer.entries(pid, ~D[2020-01-01])
  end
end

defmodule CalcServerTest do
  use ExUnit.Case

  test "CalcServer.value() returns calculated value" do
    assert CalcServer.start() |> CalcServer.value() == 0
  end

  test "CalcServer.add(pid, 1) adds 1" do
    pid = CalcServer.start()

    assert pid |> CalcServer.add(1) |> CalcServer.value() == 1
    assert pid |> CalcServer.add(4) |> CalcServer.value() == 5
  end

  test "CalcServer.sub(pid, 1) subtracts 1" do
    pid = CalcServer.start()

    assert pid |> CalcServer.sub(1) |> CalcServer.value() == -1
    assert pid |> CalcServer.sub(4) |> CalcServer.value() == -5
  end

  test "CalcServer.mul(pid, 2) multiplies 2" do
    pid = CalcServer.start()

    assert pid |> CalcServer.mul(1) |> CalcServer.value() == 0
    assert pid |> CalcServer.add(1) |> CalcServer.mul(2) |> CalcServer.value() == 2
  end

  test "CalcServer.div(pid, 2) divides by 2" do
    pid = CalcServer.start()

    assert pid |> CalcServer.div(1) |> CalcServer.value() == 0
    assert pid |> CalcServer.add(4) |> CalcServer.div(2) |> CalcServer.value() == 2
  end
end
