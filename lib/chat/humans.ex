defmodule Chat.Humans do
  @moduledoc """
  The Humans context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.Humans.Human

  @doc """
  Returns the list of humans.

  ## Examples

      iex> list_humans()
      [%Human{}, ...]

  """
  def list_humans do
    Repo.all(Human)
  end

  @doc """
  Gets a single human.

  Raises `Ecto.NoResultsError` if the Human does not exist.

  ## Examples

      iex> get_human!(123)
      %Human{}

      iex> get_human!(456)
      ** (Ecto.NoResultsError)

  """
  def get_human!(id, preloads \\ []), do: Repo.get!(Human, id) |> Repo.preload(preloads)

  @doc """
  Creates a human.

  ## Examples

      iex> create_human(%{field: value})
      {:ok, %Human{}}

      iex> create_human(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_human(attrs \\ %{}) do
    %Human{}
    |> Human.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a human.

  ## Examples

      iex> update_human(human, %{field: new_value})
      {:ok, %Human{}}

      iex> update_human(human, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_human(%Human{} = human, attrs) do
    human
    |> Human.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a human.

  ## Examples

      iex> delete_human(human)
      {:ok, %Human{}}

      iex> delete_human(human)
      {:error, %Ecto.Changeset{}}

  """
  def delete_human(%Human{} = human) do
    Repo.delete(human)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking human changes.

  ## Examples

      iex> change_human(human)
      %Ecto.Changeset{data: %Human{}}

  """
  def change_human(%Human{} = human, attrs \\ %{}) do
    Human.changeset(human, attrs)
  end
end
