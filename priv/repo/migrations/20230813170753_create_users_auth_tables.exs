defmodule ShadowsocksPh.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:shadowsocks_configs) do
      add :name, :string
      add :data, :jsonb
    end

    create unique_index(:shadowsocks_configs, [:name])

    create table(:shadowsocks_users) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :config_id, references(:shadowsocks_configs, on_delete: :delete_all), null: false
      add :name, :string
      add :password, :string
      timestamps()
    end

    create unique_index(:shadowsocks_users, [:name])
  end
end
