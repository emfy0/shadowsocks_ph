defmodule ShadowsocksPh.Shadowsocks.ShadowsocksUser do
  use Ecto.Schema

  import Ecto.Changeset

  schema "shadowsocks_users" do
    field :user_id, :integer
    field :config_id, :integer
    field :name, :string
    field :password, :string

    timestamps()
  end

  def changeset(user, attrs) do
    case user do
      nil -> cast(%__MODULE__{}, attrs, [:user_id, :config_id, :name, :password])
      user -> user |> cast(attrs, [:user_id, :config_id, :name, :password])
    end
    |> cast(attrs, [:user_id, :config_id, :name, :password])
    |> unsafe_validate_unique(:name, ShadowsocksPh.Repo)
    |> unique_constraint(:name)
  end
end
