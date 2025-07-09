defmodule Chat.Conversations.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chat.Conversations.Persona
  alias Chat.Conversations.Conversation

  schema "messages" do
    field :text, :string
    # For rag if we make it that far
    field :context, :string, default: ""
    belongs_to :persona, Persona
    belongs_to :to_persona, Persona
    belongs_to :conversation, Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :context, :persona_id, :to_persona_id, :conversation_id])
    |> validate_required([:text])
    |> assoc_constraint(:persona)
    |> assoc_constraint(:to_persona)
    |> assoc_constraint(:conversation)
  end
end
