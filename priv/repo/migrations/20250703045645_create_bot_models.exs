defmodule Chat.Repo.Migrations.CreateBotModels do
  use Ecto.Migration

  def change do
    create table(:bot_models) do
      add :name, :string
      add :spec, :map

      timestamps(type: :utc_datetime)
    end
  end
end
