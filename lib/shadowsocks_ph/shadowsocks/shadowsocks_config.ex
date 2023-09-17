defmodule ShadowsocksPh.Shadowsocks.ShadowsocksConfig do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  schema "shadowsocks_configs" do
    field :name, :string
    field :data, :map
  end

  def changeset(config \\ nil, attrs) do
    case config do
      nil -> cast(%__MODULE__{}, attrs, [:name, :data])
      config -> config |> cast(attrs, [:name, :data])
    end
    |> unique_constraint(:name)
  end

  def build_with_new_user(config, {name, password}) do
    new_user = [%{name: name, password: password}]
    config_data = config.data

    new_user_data = case config_data |> Map.get("users") do
      nil -> new_user

      users -> users ++ new_user
    end

    change(
      config,
      %{
        data: config_data |> Map.put(:users, new_user_data)
      }
    )
  end
end
