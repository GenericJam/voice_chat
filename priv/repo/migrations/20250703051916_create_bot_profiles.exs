defmodule Chat.Repo.Migrations.CreateBotProfiles do
  use Ecto.Migration

  def change do
    create table(:bot_profiles) do
      add :prompt, :text
      add :bot_model_id, references(:bot_models, on_delete: :nothing), null: false
      add :persona_id, references(:personas, on_delete: :nothing), null: true

      timestamps(type: :utc_datetime)
    end

    create index(:bot_profiles, [:bot_model_id])
    create index(:bot_profiles, [:persona_id])
  end
end
