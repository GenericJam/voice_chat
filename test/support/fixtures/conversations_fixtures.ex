defmodule Chat.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Conversations` context.
  """

  @doc """
  Generate a chat_user.
  """
  def chat_user_fixture(attrs \\ %{}) do
    {:ok, chat_user} =
      attrs
      |> Enum.into(%{
        hash: "some hash",
        name: "some name",
        photo: "some photo"
      })
      |> Chat.Conversations.create_chat_user()

    chat_user
  end
end
