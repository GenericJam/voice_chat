defmodule Chat.BotsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Bots` context.
  """

  @doc """
  Generate a bot_model.
  """
  def bot_model_fixture(attrs \\ %{}) do
    {:ok, bot_model} =
      attrs
      |> Enum.into(%{
        name: "some name",
        spec: %{}
      })
      |> Chat.Bots.create_bot_model()

    bot_model
  end

  @doc """
  Generate a bot_profile.
  """
  def bot_profile_fixture(attrs \\ %{}) do
    # Create dependencies if not provided
    bot_model = Map.get_lazy(attrs, :bot_model, fn -> bot_model_fixture() end)

    persona =
      Map.get_lazy(attrs, :persona, fn ->
        Chat.ConversationsFixtures.persona_fixture(%{role: "bot"})
      end)

    {:ok, bot_profile} =
      attrs
      |> Enum.into(%{
        prompt: "You are a helpful assistant.",
        bot_model_id: bot_model.id,
        persona_id: persona.id
      })
      |> Chat.Bots.create_bot_profile()

    bot_profile
  end
end
