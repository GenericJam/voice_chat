defmodule Chat.Repo.Migrations.CreateHumans do
  use Ecto.Migration

  def change do
    create table(:humans) do
      add :name, :string
      add :hash, :string
      add :photo, :string
      add :persona_id, references(:personas, on_delete: :nothing), null: true

      timestamps(type: :utc_datetime)
    end

    create index(:humans, [:persona_id])
  end
end
