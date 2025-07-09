defmodule Chat.Bots.BotModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bot_models" do
    field :name, :string
    field :spec, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bot_model, attrs) do
    bot_model
    |> cast(attrs, [:name, :spec])
    |> validate_required([:name])
  end
end
