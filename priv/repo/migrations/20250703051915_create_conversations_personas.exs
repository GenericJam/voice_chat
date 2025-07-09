defmodule Chat.Repo.Migrations.CreateConversationsPersonas do
  use Ecto.Migration

  def change do
    create table(:conversations_personas) do
      add :persona_id, references(:personas, on_delete: :delete_all), null: false
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
    end

    create unique_index(:conversations_personas, [:persona_id, :conversation_id])
  end
end
