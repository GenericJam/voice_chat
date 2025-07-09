defmodule Chat.ConversationsTest do
  use Chat.DataCase

  alias Chat.Conversations

  describe "personas" do
    alias Chat.Conversations.Persona

    import Chat.ConversationsFixtures

    @invalid_attrs %{name: nil, role: nil, avatar: nil}

    test "list_personas/0 returns all personas" do
      persona = persona_fixture()
      assert Conversations.list_personas() == [persona]
    end

    test "get_persona!/1 returns the persona with given id" do
      persona = persona_fixture()
      assert Conversations.get_persona!(persona.id) == persona
    end

    test "create_persona/1 with valid data creates a persona" do
      valid_attrs = %{name: "some name", role: "human", avatar: "some_name_bot_white.png"}

      assert {:ok, %Persona{} = persona} = Conversations.create_persona(valid_attrs)
      assert persona.name == "some name"
      assert persona.role == "human"
      assert persona.avatar == "some_name_bot_white.png"
    end

    test "create_persona/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_persona(@invalid_attrs)
    end

    test "update_persona/2 with valid data updates the persona" do
      persona = persona_fixture()

      update_attrs = %{
        name: "some updated name",
        role: "human",
        avatar: "some updated avatar"
      }

      assert {:ok, %Persona{} = persona} = Conversations.update_persona(persona, update_attrs)
      assert persona.name == "some updated name"
      assert persona.role == "human"
      assert persona.avatar == "some updated avatar"
    end

    test "update_persona/2 with invalid data returns error changeset" do
      persona = persona_fixture()
      assert {:error, %Ecto.Changeset{}} = Conversations.update_persona(persona, @invalid_attrs)
      assert persona == Conversations.get_persona!(persona.id)
    end

    test "delete_persona/1 deletes the persona" do
      persona = persona_fixture()
      assert {:ok, %Persona{}} = Conversations.delete_persona(persona)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_persona!(persona.id) end
    end

    test "change_persona/1 returns a persona changeset" do
      persona = persona_fixture()
      assert %Ecto.Changeset{} = Conversations.change_persona(persona)
    end
  end

  describe "conversations" do
    alias Chat.Conversations.Conversation

    import Chat.ConversationsFixtures

    @invalid_attrs %{name: nil}

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Conversations.list_conversations() == [conversation]
    end

    test "get_conversation!/1 returns the conversation with given id" do
      conversation = conversation_fixture()
      assert Conversations.get_conversation!(conversation.id) == conversation
    end

    test "create_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(valid_attrs)

      assert conversation.name == "some name"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "update_conversation/2 with valid data updates the conversation" do
      conversation = conversation_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Conversation{} = conversation} =
               Conversations.update_conversation(conversation, update_attrs)

      assert conversation.name == "some updated name"
    end

    test "update_conversation/2 with invalid data returns error changeset" do
      conversation = conversation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation(conversation, @invalid_attrs)

      assert conversation == Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation" do
      conversation = conversation_fixture()
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "change_conversation/1 returns a conversation changeset" do
      conversation = conversation_fixture()
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end
  end

  describe "messages" do
    alias Chat.Conversations.Message

    import Chat.ConversationsFixtures

    @invalid_attrs %{text: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Conversations.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Conversations.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = %{text: "some text"}

      assert {:ok, %Message{} = message} = Conversations.create_message(valid_attrs)
      assert message.text == "some text"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      update_attrs = %{text: "some updated text"}

      assert {:ok, %Message{} = message} = Conversations.update_message(message, update_attrs)
      assert message.text == "some updated text"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Conversations.update_message(message, @invalid_attrs)
      assert message == Conversations.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Conversations.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Conversations.change_message(message)
    end
  end
end
