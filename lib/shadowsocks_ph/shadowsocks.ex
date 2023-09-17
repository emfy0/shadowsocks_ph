defmodule ShadowsocksPh.Shadowsocks do 
  import Ecto.Query, warn: false
  
  alias ShadowsocksPh.Repo
  alias ShadowsocksPh.Shadowsocks.{ShadowsocksConfig, ShadowsocksUser} 

  def server_ip() do
    Application.get_env(:shadowsocks_ph, :server_ip)
  end

  def server_port() do
    Application.get_env(:shadowsocks_ph, :server_port)
    |> String.to_integer()
  end

  def server_host() do
    Application.get_env(:shadowsocks_ph, :server_host)
  end

  def build_uri(config, ss_user) do
    data = config.data
    user_name = ss_user.name
    user_password = ss_user.password

    server_part = :base64.encode(
      "#{data["method"]}:#{data["password"]}#{user_password}@#{server_ip()}:#{data["server_port"]}"
    )

    plugin_part = "?v2ray-plugin=" <> (
      %{
        mux: true,
        host: server_host(),
        mode: "websocket",
        tls: true,
        path: "/"
      }
      |> Jason.encode!()
      |> :base64.encode()
    )

    server_name = "##{user_name}"

    "ss://" <> server_part <> plugin_part <> server_name
    |> URI.encode()
  end

  def add_user_to_config_by_name(user, config_name, {username, password}) do
    config = get_config_by_name(config_name)

    case create_for_user_and_config(user, config, {username, password}) do
      {:error, error} -> {:error, error}

      _ ->
        user_prefix = user.email |> String.split("@") |> List.first()
        config_user_name = "#{user_prefix}_#{username}"
        ShadowsocksConfig.build_with_new_user(config, {config_user_name, password})
        |> Repo.insert_or_update()

        {:ok, config}
    end
  end

  def create_for_user_and_config(user, config, {name, password}) do
    ShadowsocksUser.changeset(
      nil,
      %{
        user_id: user.id,
        config_id: config.id,
        name: name,
        password: password
      }
    )
    |> Repo.insert()
  end

  def get_default_config() do
    get_config_by_name("default")
  end

  def get_config_by_name(name) do
    Repo.get_by(ShadowsocksConfig, name: name)
  end

  def create_or_update_default_config(config_data) do
    case get_default_config() do
      nil -> ShadowsocksConfig.changeset(%{name: "default", data: config_data})
      config -> ShadowsocksConfig.changeset(config, %{data: config_data})
    end
    |> Repo.insert_or_update()
  end

  def sync_manager!() do
    get_default_config().data |> ShadowsocksManager.add()
  end
end

#Repo.insert(%ShadowsocksPh.Shadowsocks.ShadowsocksConfig{name: "default", data: %{}})

