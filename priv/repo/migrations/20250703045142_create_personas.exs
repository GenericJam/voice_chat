defmodule Chat.Repo.Migrations.CreatePersonas do
  use Ecto.Migration

  def change do
    create table(:personas) do
      add :name, :string
      add :avatar, :string
      add :role, :string

      timestamps(type: :utc_datetime)
    end
  end
end
