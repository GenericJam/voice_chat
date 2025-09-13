defmodule Chat.Repo.Migrations.IncreaseMessageTextLength do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :text, :text, from: :string
    end
  end
end
