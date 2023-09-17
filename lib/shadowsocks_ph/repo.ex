defmodule ShadowsocksPh.Repo do
  use Ecto.Repo,
    otp_app: :shadowsocks_ph,
    adapter: Ecto.Adapters.SQLite3
end
