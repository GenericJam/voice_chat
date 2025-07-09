defmodule Chat.HumansFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Humans` context.
  """

  @doc """
  Generate a human.
  """
  def human_fixture(attrs \\ %{}) do
    {:ok, human} =
      attrs
      |> Enum.into(%{
        hash: "some hash",
        name: "some name",
        photo: "some photo"
      })
      |> Chat.Humans.create_human()

    human
  end
end
