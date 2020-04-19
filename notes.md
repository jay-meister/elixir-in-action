Elixir is a dynamic programming language, which means you don’t explicitly declare a variable or its type. 



### Chapter 3
Tail call optimisation:
- If function returns a function call, then tail call optimised, which does not consume memory due to a "stack push".
- Tail call eg: 
```elixir
# List Length
def list_len(list), do: list_len(0, list)
def list_len(count, []), do: count
def list_len(count, [_h | t]), do: list_len(count + 1, t)
```

- Not tail call but recursive, more declaritive, less procedural eg:
```elixir
# List Length
def list_len([]), do: 0
def list_len([_h | t]), do: 1 + list_len(t)
```
- This is not tail call optimised as the last operation is not a function call


### Chapter 5
- Erlang VM runs in one OS process
- BEAM will use as many schedulers as there are cores available (eg. 4 schedulers for quad core processor)
- Each Scheduler runs in a single OS thread
- BEAM process completely isolated, own memory allocation, can receive messages from other processes, can be supervised

**NOTE: Concurrency not equal to parallelism**
> "CPU-bound" concurrent tasks have own execution context, but if there are not multiple cores, they cannot execute in parallel.

**5.2 Message sending**
- send a message to a process: `send(pid, {:some, :elixir, :term})`
- sending a message from A to B adds the message to B's mailbox
- processes don't share memory, so the message is deep copied when it is sent
- use `send(pid, message)` to send messages
- use `receive do ... end` with multiple receive clauses to be pattern matched
- different to `case ... do` pattern match in that no match does not crash but adds message back to mailbox
- Receive Algorithm: look for oldest message that can be matched, execute if match is found, otherwise receive will wait indefinitely if no `after` clause is not provided.

- in `iex`:
```elixir
iex(1)> send(self(), :hi)
iex(2)> receive do
...(2)> :hi -> :saying_hello
...(2)> end
:saying_hello
```
- calling `receive` before sending a message will hang
- can provide `after` to prevent hang after given number of milliseconds
- `receive do ... after\n 2000 -> .../n end`

**5.3 Stateful Server Process**
- common use-case of processes
- recursive call to `receive` keeps process running and listening for messages
- tail call recursion ensures process doesn't consume additional memory - no stack overflow
- waiting for a message is not CPU intensive - puts process in suspended state


Register a process
- we can register a 'local' (to current beam instance) process with `Process.register(pid, :unique_name)`
- and then send messages without the pid: `send(:unique_name, :message)`

```elixir
iex(1)> Process.register(self(), :me)
iex(2)> send(:me, :hi)
iex(3)> receive do
...(3)>   :hi -> :hello
...(3)> end
:hello
```

**5.4 Runtime Concerns**
- A single process is always run sychronously so could become a bottleneck
- Always provide backup clause to `receive` so that we don't leave messages in the mailbox forever
- Deep copy of lots of message data could affect system performance so be wary of data passed in `send` or `spawn`


## Chapter 6 - Generic Server processes
Sever process needs to:
- Spawn new process
- Manage it's state
- Recieve & react to messages
- Send responses
- Synchronous `call` and Async `cast` functions

**OTP Behaviours**
- Our ServerProcess is a behaviour module
- It implements the generic logic which we use by creating a callback module
- Callback module satisfies the contract in defining `init/0` and `handle_call` etc
- Common OTP Behaviours that Elixir provides wrappers for: `GenServer`, `Application` & `Supervisor`
- In behaviour module, define callbacks with: `@callback default_port() :: integer`
- And then implement the relevant callback functions in the callback module:   
```elixir
@behaviour URI.Parser # this module implements the URI.Parser behaviour module
@impl true # tells compiler this is a callback function
def default_port(), do: 80
```

**GenServer**
- Requires 7 callbacks (`use GenServer` implements defaults)
- `KeyValueStore.__info__(:functions)` lists functions exported 
- Set up repeated message in `init/1` function:
- `:timer.send_interval(milliseconds, self(), :cleanup)`
- `def handle_info(:cleanup, state) do`
- Name GenServer processes with `GenServer.start(module, initial_state, name: :my_name)`
- Stopping the GenServer: return `{:stop, reason, state}` where `:normal` reason for an expected termination
- Stopping the GenServer will call the `terminate/2` callback for cleanup
- GenServer can also be stopped from client process `GenServer.stop/3`
- `Task` (short term processes), `Agent` (simple GenServer) & `GenServer` follow OTP protocol & should be used over `spawn/1`


## Chapter 7 - using Mix project
- `:erlang.system_info(:process_count)` returns number of processes running
- ExUnit's `assert` macro will raise error in case of failure, left value always expected, right value actual
- `mix test --stale --listen-on-stdin` - keeps test process open awaiting for enter key to restart tests
- encode elixir data: `:erlang.term_to_binary(elixir_term) |> :erlang.binary_to_term()`
