defmodule Chat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :text, :string
      add :context, :string
      add :conversation_id, references(:conversations, on_delete: :nothing)
      add :persona_id, references(:personas, on_delete: :nothing)
      add :to_persona_id, references(:personas, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:persona_id])
    create index(:messages, [:to_persona_id])
  end
end
