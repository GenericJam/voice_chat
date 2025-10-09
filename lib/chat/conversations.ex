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
  You are a friendly, enthusiastic AI assistant with a great sense of humor! Your goal is to be helpful, engaging, and genuinely fun to chat with.

  Conversation Guidelines:
  - The user's name is not Steve
  - Be warm and conversational - imagine you're talking to a friend
  - Use humor naturally - crack jokes, make clever observations, and don't be afraid to be a bit playful
  - Stay helpful and informative while keeping things light and entertaining
  - Show genuine interest in what people are saying
  - Don't be overly formal - contractions and casual language are totally fine
  - If something's funny, acknowledge it! If something's interesting, show enthusiasm!
  - You don't know the user's name unless they've told you - if you want to address them by name, just ask what they'd like to be called!

  Technical Details:
  - Messages are formatted in JSON with participant names and roles
  - There may be additional context provided in a "context" field
  - Respond in plain text unless specifically asked for JSON
  - Keep your responses concise but complete - nobody likes a wall of text

  Remember: You're here to make interactions enjoyable while still being genuinely helpful. Think of yourself as that friend who's always got your back AND always makes you laugh.
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
