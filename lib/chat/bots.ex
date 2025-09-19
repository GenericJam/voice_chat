defmodule Chat.Bots do
  @moduledoc """
  The Bots context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.Bots.BotModel

  @doc """
  Returns the list of bot_models.

  ## Examples

      iex> list_bot_models()
      [%BotModel{}, ...]

  """
  def list_bot_models do
    Repo.all(BotModel)
  end

  @doc """
  Gets a single bot_model.

  Raises `Ecto.NoResultsError` if the Bot model does not exist.

  ## Examples

      iex> get_bot_model!(123)
      %BotModel{}

      iex> get_bot_model!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bot_model!(id, preloads \\ []), do: Repo.get!(BotModel, id) |> Repo.preload(preloads)

  @doc """
  Creates a bot_model.

  ## Examples

      iex> create_bot_model(%{field: value})
      {:ok, %BotModel{}}

      iex> create_bot_model(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bot_model(attrs \\ %{}) do
    %BotModel{}
    |> BotModel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bot_model.

  ## Examples

      iex> update_bot_model(bot_model, %{field: new_value})
      {:ok, %BotModel{}}

      iex> update_bot_model(bot_model, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bot_model(%BotModel{} = bot_model, attrs) do
    bot_model
    |> BotModel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bot_model.

  ## Examples

      iex> delete_bot_model(bot_model)
      {:ok, %BotModel{}}

      iex> delete_bot_model(bot_model)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bot_model(%BotModel{} = bot_model) do
    Repo.delete(bot_model)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bot_model changes.

  ## Examples

      iex> change_bot_model(bot_model)
      %Ecto.Changeset{data: %BotModel{}}

  """
  def change_bot_model(%BotModel{} = bot_model, attrs \\ %{}) do
    BotModel.changeset(bot_model, attrs)
  end

  alias Chat.Bots.BotProfile

  @doc """
  Returns the list of bot_profiles.

  ## Examples

      iex> list_bot_profiles()
      [%BotProfile{}, ...]

  """
  def list_bot_profiles(preload \\ []) do
    Repo.all(BotProfile) |> Repo.preload(preload)
  end

  @doc """
  Gets a single bot_profile.

  Raises `Ecto.NoResultsError` if the Bot profile does not exist.

  ## Examples

      iex> get_bot_profile!(123)
      %BotProfile{}

      iex> get_bot_profile!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bot_profile!(id, preload \\ []), do: Repo.get!(BotProfile, id) |> Repo.preload(preload)

  def get_bot_profile_by_name(name, preload \\ []) do
    from(bp in BotProfile,
      join: persona in Chat.Conversations.Persona,
      on: bp.persona_id == persona.id,
      where: persona.name == ^name,
      preload: ^preload
    )
    |> Repo.one()
  end

  @doc """
  Creates a bot_profile.

  ## Examples

      iex> create_bot_profile(%{field: value})
      {:ok, %BotProfile{}}

      iex> create_bot_profile(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bot_profile(attrs \\ %{}) do
    %BotProfile{}
    |> BotProfile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bot_profile.

  ## Examples

      iex> update_bot_profile(bot_profile, %{field: new_value})
      {:ok, %BotProfile{}}

      iex> update_bot_profile(bot_profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bot_profile(%BotProfile{} = bot_profile, attrs) do
    # Preload persona if we're updating it via nested attributes
    bot_profile =
      if Map.has_key?(attrs, :persona) or Map.has_key?(attrs, "persona") do
        Chat.Repo.preload(bot_profile, :persona)
      else
        bot_profile
      end

    bot_profile
    |> BotProfile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bot_profile.

  ## Examples

      iex> delete_bot_profile(bot_profile)
      {:ok, %BotProfile{}}

      iex> delete_bot_profile(bot_profile)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bot_profile(%BotProfile{} = bot_profile) do
    Repo.delete(bot_profile)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bot_profile changes.

  ## Examples

      iex> change_bot_profile(bot_profile)
      %Ecto.Changeset{data: %BotProfile{}}

  """
  def change_bot_profile(%BotProfile{} = bot_profile, attrs \\ %{}) do
    BotProfile.changeset(bot_profile, attrs)
  end
end
