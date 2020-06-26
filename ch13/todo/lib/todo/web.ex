defmodule Todo.Web do
  use Plug.Router

  plug(:match)

  plug(:dispatch)

  def child_spec(_arg) do
    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: [port: Application.fetch_env!(:todo, :http_port)],
      plug: __MODULE__
    )
  end

  def init(opts) do
    IO.inspect(opts)
    opts
  end

  post "/add_entry" do
    # IO.inspect(conn)
    conn = Plug.Conn.fetch_query_params(conn)
    list_name = Map.fetch!(conn.params, "list")
    title = Map.fetch!(conn.params, "title")
    date = Map.fetch!(conn.params, "date") |> Date.from_iso8601!()

    list_name
    |> Todo.Cache.server_process()
    |> Todo.Server.add_entry(%{title: title, date: date})

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "OK")
  end

  get "/entries" do
    # IO.inspect(conn)
    conn = Plug.Conn.fetch_query_params(conn)
    list_name = Map.fetch!(conn.params, "list")
    date = Map.fetch!(conn.params, "date") |> Date.from_iso8601!()

    formatted =
      list_name
      |> Todo.Cache.server_process()
      |> Todo.Server.entries(date)
      |> Enum.map(&"#{&1.date}: #{&1.title}")
      |> Enum.join("\n")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, formatted)
  end
end
