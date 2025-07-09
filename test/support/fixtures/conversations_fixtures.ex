defmodule Chat.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Conversations` context.
  """

  @doc """
  Generate a persona.
  """
  def persona_fixture(attrs \\ %{}) do
    {:ok, persona} =
      attrs
      |> Enum.into(%{
        avatar: "some_name_bot_white.png",
        name: "some name",
        role: "human"
      })
      |> Chat.Conversations.create_persona()

    persona
  end

  @doc """
  Generate a conversation.
  """
  def conversation_fixture(attrs \\ %{}) do
    {:ok, conversation} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Chat.Conversations.create_conversation()

    conversation
  end

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        text: "some text"
      })
      |> Chat.Conversations.create_message()

    message
  end
end
