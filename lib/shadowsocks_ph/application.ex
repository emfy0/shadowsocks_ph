defmodule ShadowsocksPh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ShadowsocksPhWeb.Telemetry,
      # Start the Ecto repository
      ShadowsocksPh.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ShadowsocksPh.PubSub},
      # Start Finch
      {Finch, name: ShadowsocksPh.Finch},
      # Start the Endpoint (http/https)
      ShadowsocksPhWeb.Endpoint,
      # Start a worker by calling: ShadowsocksPh.Worker.start_link(arg)
      # {ShadowsocksPh.Worker, arg}
      {ShadowsocksManager, {'shadowsocks', 1234}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShadowsocksPh.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShadowsocksPhWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
