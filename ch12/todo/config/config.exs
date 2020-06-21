import Config

config :todo, http_port: 5454

config :todo, :database, path: "/persist/#{Mix.env()}"

import_config "#{Mix.env()}.exs"
