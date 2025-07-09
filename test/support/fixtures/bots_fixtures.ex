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
end
