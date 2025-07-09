defmodule ChatWeb.ChatLive.Index do
  use ChatWeb, :live_view

  import ChatWeb.Components.Spinner

  alias Chat.Conversations
  alias Chat.Conversations.Conversation
  alias Chat.Ollama

  @impl true
  def mount(_params, _session, socket) do
    human = Chat.Humans.get_human!(1, [:persona])
    bot_profile = Chat.Bots.get_bot_profile!(1, [:persona, :bot_model])

    socket =
      socket
      |> assign(:human, human)
      |> assign(:bot_profile, bot_profile)
      |> assign(:messages, [])
      |> assign(:dialog_input, %{"input_message" => ""})
      |> assign(:bot_streaming, false)
      |> assign(:streaming_tokens, "")
      |> assign(:conversation, %Conversation{})
      |> assign(:dialog_input_disabled, false)
      |> assign(:message_draft, "")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Chat")
    |> assign(:conversation, %Conversation{})
  end

  defp apply_action(socket, :show, %{"id" => conversation_id}) do
    show_conversation(socket, socket.assigns[:conversation], conversation_id)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Chat")
  end

  defp apply_action(socket, other, _params) do
    IO.inspect(apply_action_other: other)
    socket
  end

  # Conversation isn't loaded so fetch it from the db
  defp show_conversation(socket, nil, conversation_id) do
    conversation =
      Conversations.get_conversation!(conversation_id)
      |> Chat.Repo.preload([
        :messages,
        :personas,
        messages: [:persona, :to_persona]
      ])

    # Put the messages in order
    messages =
      conversation.messages
      |> Enum.sort(fn m1, m2 ->
        DateTime.compare(m1.inserted_at, m2.inserted_at) == :lt
      end)

    socket
    |> assign(:messages, messages)
    |> assign(:conversation, conversation)
    |> assign(:page_title, "Chat Conversation")
  end

  # Conversation already loaded
  defp show_conversation(socket, _conversation, _conversation_id) do
    socket
    |> assign(:page_title, "Chat Conversation")
  end

  @impl true
  def handle_event("send", %{"message_input" => message_input}, %{assigns: assigns} = socket) do
    # Create a conversation if this is the first message
    conversation =
      if assigns.conversation.id == nil do
        {:ok,
         %{
           conversation: conversation,
           associate_personas: :success
         }} =
          Conversations.create_conversation_with_personas(
            %{
              name: String.slice(message_input, 0..100) <> "..."
            },
            [assigns.human.persona.id, assigns.bot_profile.persona.id]
          )

        conversation
      else
        assigns.conversation
      end

    # Put the message in the db
    message =
      Conversations.create_message!(%{
        text: message_input,
        persona_id: assigns.human.persona.id,
        to_persona_id: assigns.bot_profile.persona.id,
        conversation_id: conversation.id
      })
      |> Chat.Repo.preload([:persona, :to_persona])

    messages = assigns.messages ++ [message]

    # Messages to send to Ollama
    prompt_messages =
      Conversations.messages_to_dialog(messages, assigns.bot_profile, assigns.bot_profile.prompt)

    liveview_pid = self()

    Task.start_link(fn ->
      Ollama.chat(liveview_pid, prompt_messages, assigns.bot_profile.bot_model.name)
    end)

    IO.inspect(conversation: conversation)

    socket =
      socket
      |> assign(:messages, messages)
      |> assign(:dialog_input, %{"input_message" => ""})
      |> assign(:conversation, conversation)
      |> assign(:dialog_input_disabled, true)
      |> assign(:message_draft, "")
      |> push_patch(to: ~p"/chat/#{conversation.id}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("letter", %{"message_input" => message_input}, socket) do
    socket =
      socket
      |> assign(:message_draft, message_input)

    {:noreply, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(other_event: event)
    IO.inspect(other_params: params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:token, token}, socket) do
    socket =
      socket
      |> assign(:bot_streaming, true)
      |> assign(:streaming_tokens, socket.assigns.streaming_tokens <> token)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:full_response, full_response}, %{assigns: assigns} = socket) do
    # Create bot message
    message =
      Conversations.create_message!(%{
        text: full_response,
        persona_id: assigns.bot_profile.persona.id,
        to_persona_id: assigns.human.persona.id,
        conversation_id: assigns.conversation.id
      })
      |> Chat.Repo.preload([:persona, :to_persona])

    messages = assigns.messages ++ [message]

    socket =
      socket
      |> assign(:messages, messages)
      |> assign(:streaming_tokens, "")
      |> assign(:bot_streaming, false)
      |> assign(:dialog_input_disabled, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info(other, socket) do
    IO.inspect(handle_info_other: other)
    {:noreply, socket}
  end
end
