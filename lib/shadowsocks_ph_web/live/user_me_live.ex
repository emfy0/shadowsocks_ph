defmodule ShadowsocksPhWeb.UserMeLive do
  use ShadowsocksPhWeb, :live_view

  alias ShadowsocksPh.Shadowsocks
  alias ShadowsocksPh.Shadowsocks.ShadowsocksUser
  alias ShadowsocksPh.Repo

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      My devices
    </.header>

    <div class="text-center">

      <div :for={ss_user <- @ss_users}>
        <.modal id={"ss-user-modal-#{ss_user.id}"}>
          <.header>
            <%= ss_user.name %>
          </.header>
          <% uri = Shadowsocks.build_uri(@ss_server_config, ss_user) %>
          <p class="truncate underline cursor-pointer" phx-click="copy_to_clipboard" phx-value-text={uri}>
            <%= uri %>
          </p>

          <%= raw qr_code(uri) %>
        </.modal>
        <p class="underline cursor-pointer" phx-click={show_modal("ss-user-modal-#{ss_user.id}")}>
          <%= ss_user.name %>
        </p>
      </div>

      <.simple_form for={@ss_user_form} id="create_device" phx-submit="create_device">
        <.input field={@ss_user_form[:name]} placeholder="Name" required />
        <:actions>
          <.button class="ml-2">Create new device!</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def qr_code(uri) do
    {:ok, qr} = uri
    |> QRCode.create() 
    |> QRCode.render() 

    qr
  end

  def mount(_params, _session, socket) do
    socket = socket
      |> assign(:ss_users, Repo.all(ShadowsocksUser))
      |> assign(:ss_user_form, to_form(ShadowsocksUser.changeset(nil, %{})))
      |> assign(:ss_server_config, Shadowsocks.get_default_config)

    {:ok, socket}
  end

  def handle_event("create_device", %{"shadowsocks_user" => %{ "name" => name }}, socket) do
    current_user = socket.assigns.current_user

    case Shadowsocks.add_user_to_config_by_name(
      current_user,
      "default",
      {name, :base64.encode(:crypto.strong_rand_bytes(31))}
    ) do
      {:ok, _} ->
        Shadowsocks.sync_manager!()
        {
          :noreply,
          socket
          |> assign(:ss_users, Repo.all(ShadowsocksUser))
          |> assign(:ss_user_form, to_form(ShadowsocksUser.changeset(nil, %{})))
        }

      {:error, changeset} ->
        {
          :noreply,
          socket |> assign(:ss_user_form, to_form(changeset))
        }
    end
  end

  def handle_event("copy_to_clipboard", %{"text" => text}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Copied to clipboard!")
      |> push_event("copy-to-clipboard", %{text: text})
    }
  end
end

