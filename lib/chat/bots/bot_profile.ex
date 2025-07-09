defmodule Chat.Bots.BotProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bot_profiles" do
    field :prompt, :string

    belongs_to :bot_model, Chat.Bots.BotModel

    belongs_to :persona, Chat.Conversations.Persona, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bot_profile, attrs) do
    bot_profile
    |> cast(attrs, [:prompt, :bot_model_id, :persona_id])
    |> validate_required([:prompt, :bot_model_id])
    |> assoc_constraint(:bot_model)
    |> assoc_constraint(:persona)
    |> cast_assoc(:persona, with: &Chat.Conversations.Persona.changeset/2)
  end
end
