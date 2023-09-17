defmodule ShadowsocksManager do
  use GenServer

  require Logger

  alias ShadowsocksPh.Shadowsocks

  def default_config() do
    %{
      server: "0.0.0.0",
      mode: "tcp_and_udp",
      server_port: Shadowsocks.server_port(),
      method: "aes-256-gcm",
      password: :base64.encode(:crypto.strong_rand_bytes(31)),
      plugin: "v2ray-plugin",
      plugin_opts: "server"
    }
  end

  @update_interval 3 * 1000
  @pubsub_prefix "shadowsocks_manager"
  @logger_prefix "Shadowsocks Manager: "

  def start_link({shadowsocks_domain, shadowsocks_port}) do
    GenServer.start_link(__MODULE__, {shadowsocks_domain, shadowsocks_port}, name: __MODULE__)
  end

  @impl true
  def init({shadowsocks_domain, shadowsocks_port}) do
    log("Starting Shadowsocks Manager")
    socket = open_socket(shadowsocks_domain, shadowsocks_port)

    check_and_update_config(socket)

    Process.send_after(self(), :update_stats, @update_interval)

    {:ok, {socket, nil}}
  end
  
  @impl true
  def handle_call({:send, message}, _from, {socket, last_stats}) do
    {:reply, call_manager(socket, message), {socket, last_stats}}
  end

  def handle_call(:current_stats, _from, {socket, last_stats}) do
    {:reply, last_stats, {socket, last_stats}}
  end

  @impl true
  def handle_info(:update_stats, {socket, _last_stats}) do
    last_stats = call_manager(socket, "ping")

    log("Stats updated: #{Jason.encode!(last_stats)}")

    Phoenix.PubSub.broadcast(ShadowsocksPh.PubSub, "#{@pubsub_prefix}:stats_updated", last_stats)

    Process.send_after(self(), :update_stats, @update_interval)
    {:noreply, {socket, last_stats}}
  end

  def current_stats() do
    GenServer.call(__MODULE__, :current_stats)
  end

  def add(config) do
    form_message("add", config) |> send()
  end

  def remove(config) do
    form_message("remove", config) |> send()
  end

  def list() do
    form_message("list") |> send()
  end

  def form_message(verb, config \\ nil) do
    json_config = case config do
      nil -> ""
      config -> config |> Jason.encode!() |> (& ": #{&1}").()
    end

    "#{verb}#{json_config}"
  end

  defp send(message) do
    GenServer.call(__MODULE__, {:send, message})
  end

  defp call_manager(socket, message) do
    :socket.send(socket, message, 1000)
    {:ok, data} = :socket.recv(socket, [], 1000)

    case data do
      "ok\n" -> :ok
      data ->
        case Jason.decode(data) do
          {:ok, data} -> data
          {:error, _} ->
            data |> String.split(": ") |> List.last() |> Jason.decode!()
        end
    end
  end

  defp open_socket(shadowsocks_domain, shadowsocks_port) do
    {:ok, socket} = :socket.open(:inet, :dgram)

    :socket.bind(
      socket, %{ family: :inet, port: 0, addr: {0, 0, 0, 0} }
    )

    connect_to_shadowsocks({shadowsocks_domain, shadowsocks_port}, socket)
  end

  defp check_and_update_config(socket) do
    reply = call_manager(socket, "list")

    config = case Shadowsocks.get_default_config() do
      nil ->
        default_config() |> Shadowsocks.create_or_update_default_config()
        default_config()
      config -> config |> Map.get(:data)
    end

    if reply == [] do
      call_manager(
        socket, form_message("add", config)
      )
    end
  end

  defp connect_to_shadowsocks({shadowsocks_domain, shadowsocks_port}, socket) do
    connet_socket(socket, shadowsocks_domain, shadowsocks_port)
    socket
  end

  defp connet_socket(socket, domain, port) do
    log("Connecting to #{domain}:#{port}")

    case :socket.connect(
      socket, %{ family: :inet, port: port, addr: get_ip(domain) }
    ) do
      :ok -> :ok
      {:error, _} ->
        log("Retrying to connect to #{domain}:#{port}")
        Process.sleep(1000)
        connet_socket(socket, domain, port)
    end

    socket
  end

  defp get_ip(domain) do
    case :inet.getaddr(domain, :inet) do
      {:ok, ip_addr} -> ip_addr
      {:error, _} ->
        log("Retrying to get ip for #{domain}")
        Process.sleep(1000)
        get_ip(domain)
    end
  end

  defp log(message) do
    Logger.info("#{@logger_prefix}#{message}")
  end
end

#{:ok, pid} = GenServer.start_link(Shadowsocks.Manager, {'shadowsocks', 1234})
#GenServer.cast(pid, {:send, "ping"})
#GenServer.call(pid, :recv)

