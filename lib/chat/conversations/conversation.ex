defmodule Chat.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :name, :string

    many_to_many :personas, Chat.Conversations.Persona, join_through: "conversations_personas"

    has_many :messages, Chat.Conversations.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
