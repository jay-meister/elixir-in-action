defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  def loop(module, state) do
    receive do
      {:call, caller, request} ->
        {:ok, response, new_state} = module.handle_call(request, state)
        send(caller, response)
        loop(module, new_state)

      {:cast, request} ->
        {:ok, new_state} = module.handle_cast(request, state)
        loop(module, new_state)
    end
  end

  def call(pid, request) do
    send(pid, {:call, self(), request})

    receive do
      response -> response
    end
  end

  def cast(pid, request) do
    send(pid, {:cast, request})
    :ok
  end
end

defmodule KeyVal do
  # interface functions
  def start() do
    ServerProcess.start(__MODULE__)
  end

  def get(pid, key) do
    ServerProcess.call(pid, {:get, key})
  end

  def put(pid, key, val) do
    ServerProcess.cast(pid, {:put, key, val})
  end

  # server callback functions
  def init do
    %{}
  end

  def handle_cast({:put, key, value}, state) do
    new_state = Map.put(state, key, value)
    {:ok, new_state}
  end

  def handle_call({:get, key}, state) do
    {:ok, state[key], state}
  end
end

defmodule Stack do
  # interface functions
  def start() do
    ServerProcess.start(__MODULE__)
  end

  def pop(pid) do
    ServerProcess.call(pid, :pop)
  end

  def push(pid, val) do
    ServerProcess.cast(pid, {:push, val})
  end

  # server callback functions
  def init() do
    [:hello]
  end

  def handle_call(:pop, [head | tail]) do
    {:ok, head, tail}
  end

  def handle_call({:push, value}, state) do
    new_state = [value | state]
    {:ok, new_state, new_state}
  end

  def handle_call(_msg, state) do
    IO.inspect({:error, :invalid_call})

    {:ok, :invalid_call, state}
  end

  def handle_cast({:push, value}, state) do
    {:ok, [value | state]}
  end

  def handle_cast(_msg, state) do
    IO.inspect({:error, :invalid_call})

    {:ok, :invalid_cast, state}
  end
end

# $ iex ./ch06/server_process.ex
# iex(1)> pid = Stack.start()
# #PID<0.118.0>
# iex(2)> Stack.pop(pid)
# :hello
# iex(3)> Stack.push(pid, :hi)
# :ok
# iex(4)> Stack.pop(pid)
# :hi
