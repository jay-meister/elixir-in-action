import Config

config :todo, http_port: System.get_env("PORT", "5454") |> String.to_integer()

config :todo, :database, path: "/persist/#{Mix.env()}"

import_config "#{Mix.env()}.exs"
