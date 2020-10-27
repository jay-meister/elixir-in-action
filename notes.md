Elixir is a dynamic programming language, which means you don’t explicitly declare a variable or its type. 



# Chapter 3
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


# Chapter 5
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


# Chapter 6 - Generic Server processes
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


# Chapter 7 - using Mix project
- `:erlang.system_info(:process_count)` returns number of processes running
- ExUnit's `assert` macro will raise error in case of failure, left value always expected, right value actual
- `mix test --stale --listen-on-stdin` - keeps test process open awaiting for enter key to restart tests
- encode elixir data: `:erlang.term_to_binary(elixir_term) |> :erlang.binary_to_term()`

# Chapter 8 - Fault Tolerance
- 3 types of runtime error: error: `raise(reason)`, exit: (`exit(reason)`), throw: (`throw(reason)`)
- use try/catch to catch errors
- try/catch returns last executed line from either do or catch block
```elixir
try do
  ...
catch error_type, error_value ->
  # error_type in [:error, :exit, :throw]
  # error_value usually the error that got raised (eg. %RuntimeError{} struct)
end
```

#### Linked processes
- Link to external processes with `Process.link/1` (existing) & `spawn_link/1` (spawns new)
- linking processes provides exit signal to proc a if linked proc b crashes
- exit signal contains proc pid & exit reason (eg. `:normal`)
- if linked process crashes with exit reason not `:normal`, then current process terminates as well
- a link creates a bidirectional connection
```elixir
# process 2 output is never printed because its linked process crashed
spawn(fn ->
 spawn_link(fn ->    
            Process.sleep(1000)
            IO.puts("Process 2 finished")
          end)

          raise("Something went wrong")
        end)
```

##### Trap exits
- `Process.flag(:trap_exit, true)`
- Trapping exits prevents linked process crash from bringing down current process
- When trapping exits, the crash will appear in parent process' mailbox
- Exit message of shape: `{:EXIT, from_pid, exit_reason}`
```elixir
spawn(fn ->
  Process.flag(:trap_exit, true)    
  spawn_link(fn -> raise("Something went wrong") end)    

  receive do    
    msg -> IO.inspect(msg)    
  end    
end)
# {
#   :EXIT, 
#   #PID<0.151.0>, 
#   {
#     %RuntimeError{message: "Something went wrong"}, 
#     [{:erl_eval, :do_apply, 6, [file: 'erl_eval.erl', line: 678]}]
#   }
# }
```

##### Monitors
- `monitor_ref = Process.monitor(target_pid)` 
- Sets unidirectional monitoring of target pid
- If target_pid dies, current pid recieves a message to mailbox (does not crash)
- Message of shape:  `{:DOWN, monitor_ref, :process, from_pid, exit_reason}`
```elixir
iex(1)> pid = spawn(fn -> :timer.sleep(:infinity) end)
iex(2)> monitor_ref = Process.monitor(pid)
iex(3)> Process.exit(pid, :a_reason)
iex(4)> receive do
...(4)> msg -> IO.inspect msg
...(4)> end
{:DOWN, #Reference<0.1609168279.1991245828.99702>, :process, #PID<0.111.0>,
 :a_reason}
 ```
- GenServer sets up a monitor that targets server process - if a `:DOWN` message is received GenServer detects and raises exit signal in client process

#### Supervisors
```elixir
# start supervisor process with Todo.Cache as supervised child
{:ok, sup_pid} = Supervisor.start_link([Todo.Cache] , strategy: :one_for_one)
# force kill todo cache
Process.exit(Process.whereis(Todo.Cache), :kill)  # it restarts
# check number of processes running
:erlang.system_info(:process_count)
```
- restart frequency defines how many restarts in how many seconds the supervisior should attempt before bringing supervisor down

**Child Spec**
- Basic child specification (how to start, how to restart, unique id):
```elixir
%{
 id: Todo.Cache,    
 start: {Todo.Cache, :start_link, [nil]},    
}
```
- `use GenServer` sets up some defaults so that the module can be callback module to obtain child spec. See docs.



# Chapter 9 - Isolating Error Effects

#### Supervision Tree
- Worker processes are started synchronously - `init` should run quickly
- Registry module uses ETS to register current pid using complex key-value pair
```elixir
Registry.start_link(name: :my_reg, keys: :unique)
Registry.register(:my_reg, {:a, :complex, :key}, {:a, :complex, :value})
Registry.lookup(:my_reg, {:a, :complex, :key})
# [{_registered_pid = #PID<0.142.0>, {:a, :complex, :value}}]
self() # #PID<0.142.0>

Registry.lookup(:my_reg, {:a, :terminated, :process})
# []
```

##### Via tuples
- use via tuples to register genservers with complex names
- can name a GenServer with via tuple: `name: {:via, some_module, some_arg}`
- `some_module` acts as a registry
- `some_arg` is data passed to functions in `some_module` and must at least contain the name to register the process under
- call/cast GenServer with via tuple and GenServer will discover the pid
- using Registry module: `{:via, Registry, {:my_registry, {__MODULE__, id}}}`

```elixir
defmodule EchoServer do
  use GenServer
  def start_link(id),
    do: GenServer.start_link(__MODULE__, nil, name: via_tuple(id))

  def call(id, some_request),
    do: GenServer.call(via_tuple(id), some_request)

  defp via_tuple(id), 
    do: {:via, Registry, {:my_registry, {__MODULE__, id}}}

  def handle_call(some_request, _, state), 
    do {:reply, some_request, state}
  end
end
# iex
Registry.start_link(name: :my_registry, keys: :unique)
EchoServer.start_link({:server, 1})
EchoServer.call({:server, 1}, "heylo")
```


##### OTP compliance
- Supervisor starts a child, it ensure it is OTP compliant
- [Erlang docs](http://erlang.org/doc/design_principles/spec_proc.html#id80464) for more details
- `use GenServer, Supervisor, Registry` will make child OTP compliant
- Plain processes started from workers such as GenServer via `start_link` is not compliant and should be avoided
- OTP compliance ensures better logging


##### Process shutdown
- Usually Supervisor subtree is terminated in graceful manner
- For GenServers, this involves invoking `terminate/2`, it must also be trapping exits set up in it's `init/1` callback
- `:shutdown` option in child_spec indicates how long supervisor should wait before forcing shutdown before force terminating. Defaults to `5000` in workers and `:infinity` in supervisors


##### Process restart
- `restart: :temporary` is not restarted after termination
- `restart: :transient` is only restarted if it is termated abnormally


###### Restart strategy
- `:one_for_one` - independent siblings - if worker terminates, restart on in it's place
- `:one_for_all` - tightly linked siblings - if worker terminates, terminate all other children and restart them
- `:rest_for_one` - younger siblings depend on older - if worker terminates, terminate all _younger siblings_ and then restart them


##### Dynamic Supervisor
- use Dynamic Supervisor to supervise children dynamically
```elixir
DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
...
# start a child process to be supervised
DynamicSupervisor.start_child(__MODULE__, {ChildModule, init_value})
```



# Chapter 10 Beyond GenServer
useful erlang functions:
- `:timer.seconds(10)`
- `:erlang.memory(:total)`

#### Tasks

##### Awaited Tasks
- awaited tasks are linked to starter process
```iex
t = Task.async(fn -> Process.sleep(2000); {:ok, :result} end)
# immediately returns %Task{owner: #PID<100>, pid: #PID<101>, ref: #Reference<...>}
Task.await(t)
# {:ok, :result}
```

##### Non-awaited Tasks
- `Task.start_link(&loop/0)`
- linked to starter process, does not send message back to starter process
- think of as 'OTP-compliant' versin of `spawn_link`
- can therefore be supervised. eg:
```elixir
defmodule Todo.Metrics do
  use Task

  def start_link(_arg), do: Task.start_link(&loop/0)
  def loop(), do 
    Process.sleep(10_000); collect_metrics(); loop()
  end
```

#### Agents
- Just and abstraction on top of GenServer, use lamdas to interact with state
- If a GenServer powered module only requires `init/1`, `handle_cast/2`, `handle_call/3`, it can be replaced with an agent. If it requires `handle_info/2` or `terminate/1` then keep as a GenServer.
- `Agent.update` is synchronous, use `Async.cast` for async
- State easily corrupted through lamdas - always wrap interface in module


#### ETS tables
- `mix run -e "Bench.run(KeyValue)"`
- compiles, starts beam instance, executes command
- ETS tables can handle concurrent read & writes
- ETS tables are powered by C code, with process-like semantics
- Data coming in and out is deep copied
- ETS table continues to consume memory until owner process is terminated
- Each row is arbitrarily sized tuple, first element represents the key
- Initial size of ~ 2kb (bigger than process - don't overuse)
```elixir
table = :ets.new(:my_table_name, [])
# #Reference<0.970221231.4117102596.53103>
:ets.insert(table, {:key_1, 1})
# true
:ets.lookup(table, :key_1)
# [key_1: 1]
```
- Table options:
- Table type (eg :set or :bag) & permissions (:protected, :public, :private) can be configured in options
- `:named_table` registers the tables name to be used instead of reference


# Chapter 11 - Working with Components
##### Applications
- ...
- folder structure is conventions:
```
lib/
  Appl1/
    ebin/
    priv/
    ..
  Appl2/
    ebin/
    priv/
    ..
```

##### Starting a server with plug/cowboy
```elixir
Plug.Adapters.Cowboy.child_spec(
  scheme: :http, 
  options: [port: 5454],
  plug: __MODULE__
)
```

##### Configuring Application
- Automatically checks in `config/config.exs`


# Chapter 12 - Building distributed system
##### Starting a cluster
- Elixir/Erlang provides distribution primitives: processes and messages
- Connect nodes (named BEAM instance) to a cluster
- `iex --sname node1@localhost`
- `--sname` turns BEAM instance into a node with name `node1@localhost`
- `node1` is unique name on machine, `localhost` defines the host
- `--sname` denotes "short name" - host machine identified by name only
- "long name" is possible - host machine identified by symbolic name or an IP address
```elixir
# iex --sname node1@localhost
node() # outputs node name `:node1@localhost` (an atom)
Node.connect(:node2@localhost) # - connect second node to first node
Node.list() # shows both nodes are connected to each other
Node.connect(:node3@localhost) # - all nodes now inter-connected
Node.list([:this, :visible]) # - show all visible nodes in cluster including current
```

##### Communicating
```elixir
# spawn a process on remote node
Node.spawn(:node2@localhost, fn -> IO.puts("HI from #{node()}") end) # HI from node2@localhost
# erlang ensures I/O calls are forwarded to 'group leader' (the owning process), (:node1@localhost in this case)
caller = self()
Node.spawn(:node2@localhost, fn -> send(caller, {:response, 1+2})) end) # sends caller process a message

# locally register process:
Process.register(self(), :shell)
send(:shell, "hi from #{node()}") # hi from :node1@localhost

# can send message to a locally registered process on remote node:
# in node2@localhost:
send({:shell, :node1@localhost}, "hi from #{node()}")
# in node1@localhost:
flush() # hi from :node2@localhost
```

##### Process discovery
- global registration
```elixir
# iex --sname node1@localhost
:global.register_name({:todo_list, "bob"}, self())
# :yes (success)
:global.whereis_name({:todo_list, "bob"})
#PID<0.114.0>

# iex --sname node2@localhost
:global.register_name({:todo_list, "bob"}, self())
# :no (failure)
pid = :global.whereis_name({:todo_list, "bob"})
# #PID<11115.114.0>
Kernel.node(pid)
# :node1@localhost
```
- can also globally register genserver with: `name: {:global, some_unique_global_alias}`

- use `:pg2` module for registering groups of processes across cluster under arbitrary names
```elixir
# n1@localhost
:pg2.create({:todo_list, "bob"})

# n2@localhost
Node.connect(:n1@localhost)
:pg2.which_groups()
# [todo_list: "bob"]
:pg2.join({:todo_list, "bob"}, self())
:pg2.get_members({:todo_list, "bob"})
# [#PID<0.114.0>]

# n1@localhost
:pg2.join({:todo_list, "bob"}, self())
:pg2.get_members({:todo_list, "bob"})
# [#PID<0.114.0>, #PID<11677.114.0>]
```

##### Links and monitors
- work the same as in single node:

```elixir
# n1@localhost
:global.register({:todo_list, "bob"}, self())

# n2@localhost
Node.connect(:n1@localhost)
Process.monitor(:global.whereis_name({:todo_list, "bob"}))

# now terminate n1@localhost,
# flush n2@localhost:
flush()
# {:DOWN, #Reference<0.1764662104.4048289793.172202>, :process, #PID<11188.114.0>, :noconnection}
```

##### Splits in the cluster
```elixir
iex(node1@localhost)> :net_kernel.monitor_nodes(true)
# receive messages when nodes join/leave cluster

# connect node2 to node1
iex(node2@localhost)> Node.connect(:node1@localhost) 

iex(node1@localhost)> flush()
# {:nodeup, :node2@localhost}

# terminate node2

iex(node1@localhost)> flush()
# {:nodedown, :node2@localhost}
```

### Network considerations
##### Node naming
- short name: `arbitrary_prefix@host`
- long name: `arbitrary_prefix@host.domain`
- long name uses --name prefix: `iex --name node1@127.0.0.1`
- symbolic long name: `iex --name node1@some_host.some_domain`
- `host` or `host.domain` must be resolvable to IP address of machine running BEAM instance
- long-named hosts cannot connect to short-named hosts

##### Cookies
- cookie used as passphrase to authorise connections between nodes
- cookie string is generated when virst starting BEAM on machine in `.erlang.cookie` file
- use `Node.get_cookie()` to view in iex. All iex sessions on same machine share same cookie
- in order to connect to a remote node, both nodes must share same cookie
- use `Node.set_cookie(:some_cookie)` to set a new cookie or use `iex --cookie some_cookie` option

##### Hidden nodes
- can connect to cluster as hidden node if node is separate enough. eg node which collects metrics.
- start BEAM with `--hidden` option
- `:global`, `:rpc` & `:pg2` ignore hidden nodes
- `Node.list([:connected])` and `Node.list([:hidden])` include hidden nodes

##### Firewalls
- Erlang Port Mapper Daemon (EPMD) is OS process automatically started when first Erl node started
- Connecting to remote node, first queries EPMD to determine port & create connection
- EPMD listens on 4369 which must be accissible from remote machines
- Each node also listens on random port, use `:inet_dist_listen_min` to restrict port
- manually inspect ports of all nodes on host machine: `:net_adm.names()` or `epmd -names` from command line


# Chapter 13 - Running the system
##### Running system with Elixir tools
- `iex -S mix` starts BEAM and starts OTP application & opens interactive shell
- `mix run --no-halt` starts BEAM and starts OTP application
- `elixir -S mix run --no-halt` - allows us to run application in background
- `elixir --erl "-detached" --sname todo_system@localhost -S mix run --no-halt` - run in background on named node
```
$ epmd -names
# epmd: up and running on port 4369 with data:
# name todo_system at port 52470

$ curl "http://localhost:52470/entries?list=bob&date=2018-12-20"
# this should get a response, but my system doesn't seem to be working properly

$ iex --sname debugger@localhost --remsh todo_system@localhost --hidden
# connect remote shell session to running BEAM instance 
iex> System.stop() # stop todo system from remote shell

```

##### Running scripts
- `elixir file_name.exs` - execute script, all modules compiled in memory
- `mix run -e MyTool.Runner.run` - starts OTP app & runs a function within mix project
- `mix escript.build` build an "escript" which creates a CLI script, only erlang needed on host machine

##### Running in prod
- `MIX_ENV=prod elixir -S mix run --no-halt`
- When measuring load/speed performance, always compile in PROD for real-life results

### OTP Releases
- standalone compiled runnable system
- can include erlang binaries making it self-sufficient
- doesn't contain artefacts such as docs, tests, source code
- can build system on dev machine and ship only binary artefacts

##### Distillary
- `mix release.init` initialise `rel/` directory
- `MIX_ENV=prod mix release` - build new release
- `def project, do: [preferred_cli_env: [release: :prod]]` - set default release env in mix.exs
- `_build/prod/rel/todo` - can now run on another machine with same architecture/os
- `build/prod/rel/todo/bin/todo` list possible commands
- `_build/prod/rel/todo/bin/todo start_iex` - start system with iex shell
- `_build/prod/rel/todo/bin/todo remote` - connects to running system via remote shell
- `_build/prod/rel/todo/bin/todo daemon` - starts in background
- `_build/prod/rel/todo/bin/todo stop` - stops system 

##### Release contents
- `_build/prod/rel/todo/lib` contains runtime dependencies (all otp applications)
- In each is `ebin` subfolder containing compiled binaries
- `Application.app_dir(:an_app_name, "priv")` for `/priv` absolute path which is automatically added to application folder in release
- `_build/prod/rel/todo/releases/0.1.0/vm.args` - flags passed to erlang runtime
- `_build/prod/rel/todo/releases/0.1.0/sys.config` - contains OTP env vars from `mix.exs` & `config.exs`
- `_build/prod/rel/todo/releases/0.1.0` - contains compressed tarbell named `todo.tar.gz` which is compressed version of the entire release (I can't find this, maybe moved). To deploy to a target meachine, copy this file, unpack it, start system with `bin/todo start`.


### Analysing system behaviour
- `:timer.tc` - time a function
- Benchfella / Benchee - benchmarking tools
- `mix profile.cprof` / `eprof` / `fprof` profiling tools

##### Observe remote node with `:observer`:
- add `:runtime_tools` to `extra_applications` in `mix.exs`
- connect to running release: `iex --hidden --name observer@127.0.0.1 --cookie todo`
- run `:observer.start()`, then, click Nodes and select the remote node 
- see `wobserver` for http observer-like tool

##### Tracing
```elixir
# start tracing genserver
:sys.trace(Todo.Cache.server_process("bob"), true)
# starting todo server bob on node todo@Jacks-MacBook-Pro-3
# :ok
# *DBG* {'Elixir.Todo.Server',<<"bob">>} 
# got call { entries, #{'__struct__' => 'Elixir.Date', calendar => 'Elixir.Calendar.ISO', day => 20,month => 12, year => 2018}} 
# from <0.1106.0> 
#
# *DBG* {'Elixir.Todo.Server',<<"bob">>} 
# sent [] to <0.1106.0>, 
# new state {<<"bob">>, #{'__struct__' => 'Elixir.Todo.List', auto_id => 1, entries => #{}}}

# stop tracing genserver
:sys.trace(Todo.Cache.server_process("bob"), false)
```
Tracing will be expensive if large state or traced process is under heavy load

- `:sys.get_state/1` & `:sys.replace_state/2` allow us to read & update OTP processes state (meant for debugging purposes)
- `:erlang.trace/3` function allows us to subscribe to events in system such as message-passing or function calls
- `:dbg` module simplifies tracing - example in book I couldn't get to work due to host name of running server
- see package `recon` for analyzing a running BEAM node
