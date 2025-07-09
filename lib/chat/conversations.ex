defmodule Chat.Conversations do
  @moduledoc """
  The Conversations context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.Conversations.Persona

  alias Chat.Conversations.Message

  @doc """
  Returns the list of personas.

  ## Examples

      iex> list_personas()
      [%Persona{}, ...]

  """
  def list_personas do
    Repo.all(Persona)
  end

  @doc """
  Gets a single persona.

  Raises `Ecto.NoResultsError` if the Persona does not exist.

  ## Examples

      iex> get_persona!(123)
      %Persona{}

      iex> get_persona!(456)
      ** (Ecto.NoResultsError)

  """
  def get_persona!(id), do: Repo.get!(Persona, id)

  @doc """
  Creates a persona.

  ## Examples

      iex> create_persona(%{field: value})
      {:ok, %Persona{}}

      iex> create_persona(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_persona(attrs \\ %{}) do
    attrs = create_avatar(attrs)

    %Persona{}
    |> Persona.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a persona.

  ## Examples

      iex> update_persona(persona, %{field: new_value})
      {:ok, %Persona{}}

      iex> update_persona(persona, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_persona(%Persona{} = persona, attrs) do
    persona
    |> Persona.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a persona.

  ## Examples

      iex> delete_persona(persona)
      {:ok, %Persona{}}

      iex> delete_persona(persona)
      {:error, %Ecto.Changeset{}}

  """
  def delete_persona(%Persona{} = persona) do
    Repo.delete(persona)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking persona changes.

  ## Examples

      iex> change_persona(persona)
      %Ecto.Changeset{data: %Persona{}}

  """
  def change_persona(%Persona{} = persona, attrs \\ %{}) do
    Persona.changeset(persona, attrs)
  end

  alias Chat.Conversations.Conversation

  @doc """
  Returns the list of conversations.

  ## Examples

      iex> list_conversations()
      [%Conversation{}, ...]

  """
  def list_conversations do
    Repo.all(Conversation)
  end

  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.

  ## Examples

      iex> get_conversation!(123)
      %Conversation{}

      iex> get_conversation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation!(id), do: Repo.get!(Conversation, id)

  @doc """
  Creates a conversation.

  ## Examples

      iex> create_conversation(%{field: value})
      {:ok, %Conversation{}}

      iex> create_conversation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def create_conversation_with_personas(attrs, persona_ids) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:conversation, Conversation.changeset(%Conversation{}, attrs))
    |> Ecto.Multi.run(:associate_personas, fn _repo, %{conversation: conversation} ->
      # Prepare the associations for the join table
      associations =
        persona_ids
        |> Enum.map(fn persona_id ->
          %{conversation_id: conversation.id, persona_id: persona_id}
        end)

      # Insert associations
      {2, nil} = Repo.insert_all(Chat.Conversations.ConversationPersona, associations)
      {:ok, :success}
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a conversation.

  ## Examples

      iex> update_conversation(conversation, %{field: new_value})
      {:ok, %Conversation{}}

      iex> update_conversation(conversation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a conversation.

  ## Examples

      iex> delete_conversation(conversation)
      {:ok, %Conversation{}}

      iex> delete_conversation(conversation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

      iex> change_conversation(conversation)
      %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end

  @system_prompt "You are a helpful assistant."

  @prepend_system_prompt """
  You are in a conversation with perhaps more than one human.
  Each participant is labelled with their name and role using JSON to delimit the statements.
  There may be additional context to the question which will be a field in the JSON as "context".
  You can address other participants by prepending their name with @ like @Dave.
  If you address them with @ it will trigger a response. If you don't want a response just use their name without @.
  Every message is from someone and it may be to someone. The role of the participants are bot or user.
  Please respond in markdown or plain text. Do not respond in JSON unless the question specifically asks for a JSON response.
  """

  def messages_to_dialog(
        [%Message{} | _] = messages,
        %Chat.Bots.BotProfile{} = bot_profile,
        system_prompt \\ nil
      ) do
    messages = messages |> Repo.preload([:persona, :to_persona])

    bot_profile = bot_profile |> Repo.preload([:persona])

    chat_messages =
      messages
      |> Enum.map(fn %Message{
                       text: text,
                       persona: persona,
                       to_persona: to_persona,
                       context: context
                     } ->
        if persona == bot_profile.persona do
          LangChain.Message.new_assistant!(text)
        else
          %{
            message: text,
            from: %{name: persona.name, role: persona.role},
            to: %{name: to_persona.name, role: to_persona.role},
            context: context
          }
          |> Jason.encode!()
          |> LangChain.Message.new_user!()
        end
      end)

    [
      LangChain.Message.new_system!(
        @prepend_system_prompt <>
          "Your name is #{bot_profile.persona.name}" <> (system_prompt || @system_prompt)
      )
      | chat_messages
    ]
  end

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def create_message!(attrs \\ %{}) do
    {:ok, %Message{} = message} = create_message(attrs)
    message
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_avatar(%{"name" => nil} = attrs) do
    attrs
  end

  def create_avatar(%{"name" => ""} = attrs) do
    attrs
  end

  def create_avatar(%{"name" => name, "role" => role} = attrs) do
    avatar_color = if role == "bot", do: :bot_grey, else: :bot_white

    avatar = Chat.Avatarex.avatar!(name, avatar_color)

    if Map.has_key?(attrs, "avatar") do
      Map.update!(attrs, "avatar", fn _ -> avatar end)
    else
      Map.put(attrs, "avatar", avatar)
    end
  end

  def create_avatar(%{name: nil} = attrs) do
    attrs
  end

  def create_avatar(%{name: ""} = attrs) do
    attrs
  end

  def create_avatar(%{name: name, role: role} = attrs) do
    avatar_color = if role == "bot", do: :bot_grey, else: :bot_white

    avatar = Chat.Avatarex.avatar!(name, avatar_color)

    if Map.has_key?(attrs, :avatar) do
      Map.update!(attrs, :avatar, fn _ -> avatar end)
    else
      Map.put(attrs, :avatar, avatar)
    end
  end
end
