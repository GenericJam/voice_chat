defmodule Chat.Conversations.ConversationPersona do
  @moduledoc """
  A cross table between Conversation and Persona
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Chat.Conversations.Persona
  alias Chat.Conversations.Conversation

  schema "conversations_personas" do
    belongs_to :conversation, Conversation
    belongs_to :persona, Persona
  end

  @doc false
  def changeset(conversation_persona, attrs) do
    conversation_persona
    |> cast(attrs, [:conversation_id, :persona_id])
    |> assoc_constraint(:conversation)
    |> assoc_constraint(:persona)
  end
end
