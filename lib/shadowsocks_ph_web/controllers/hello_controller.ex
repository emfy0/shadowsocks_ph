defmodule ShadowsocksPhWeb.HelloController do
  use ShadowsocksPhWeb, :controller

  def index(conn, _) do
    {:ok, %{url: url, session_params: session_params}} = Assent.Strategy.Github.authorize_url(config())

    conn |> put_session(:session_params, session_params) |> redirect(external: url)
  end

  def github_callback(conn, params) do
    {:ok, user_params} =
      config()
      |> Assent.Config.put(:session_params, get_session(conn, :session_params))
      |> Assent.Strategy.Github.callback(params)

    render(conn, :index, user_params: user_params)
  end

  defp config() do
    [
      client_id: "aafbff5d676a4a6b263e",
      client_secret: "1fe89c8cec4c864342ad93aa7a1ee2d319807438",
      redirect_uri: "http://localhost:4000/oauth/github/callback"
    ]
  end
end

