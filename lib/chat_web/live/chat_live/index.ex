defmodule ChatWeb.ChatLive.Index do
  use ChatWeb, :live_view

  import ChatWeb.Components.Spinner

  alias Chat.Conversations
  alias Chat.Conversations.Conversation
  alias Chat.Ollama

  @impl true
  def mount(_params, _session, socket) do
    human = Chat.Humans.get_human!(1, [:persona])
    bot_profile = Chat.Bots.get_bot_profile!(4, [:persona, :bot_model])

    # Kokoro TTS voices organized by category
    kokoro_voices = %{
      "American English Female" => [
        %{id: "af_alloy", name: "Alloy"},
        %{id: "af_aoede", name: "Aoede"},
        %{id: "af_bella", name: "Bella"},
        %{id: "af_heart", name: "Heart"},
        %{id: "af_jessica", name: "Jessica"},
        %{id: "af_kore", name: "Kore"},
        %{id: "af_nicole", name: "Nicole"},
        %{id: "af_nova", name: "Nova"},
        %{id: "af_river", name: "River"},
        %{id: "af_sarah", name: "Sarah"},
        %{id: "af_sky", name: "Sky"}
      ],
      "American English Male" => [
        %{id: "am_adam", name: "Adam"},
        %{id: "am_echo", name: "Echo"},
        %{id: "am_eric", name: "Eric"},
        %{id: "am_fenrir", name: "Fenrir"},
        %{id: "am_liam", name: "Liam"},
        %{id: "am_michael", name: "Michael"},
        %{id: "am_onyx", name: "Onyx"},
        %{id: "am_puck", name: "Puck"},
        %{id: "am_santa", name: "Santa"}
      ],
      "British English Female" => [
        %{id: "bf_alice", name: "Alice"},
        %{id: "bf_emma", name: "Emma"},
        %{id: "bf_isabella", name: "Isabella"},
        %{id: "bf_lily", name: "Lily"}
      ],
      "British English Male" => [
        %{id: "bm_daniel", name: "Daniel"},
        %{id: "bm_fable", name: "Fable"},
        %{id: "bm_george", name: "George"},
        %{id: "bm_lewis", name: "Lewis"}
      ]
    }

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
      |> assign(:speech_listening, false)
      |> assign(:speech_supported, true)
      |> assign(:speech_interim_text, "")
      |> assign(:auto_submit_countdown, 0)
      |> assign(:speech_muted, false)
      |> assign(:tts_enabled, true)
      |> assign(:tts_speaking, false)
      |> assign(:tts_auto_speak, true)
      |> assign(:available_voices, %{})
      |> assign(:selected_voice, nil)
      |> assign(:voice_testing, false)
      |> assign(:voice_settings_open, false)
      |> assign(:selected_person, "julia")
      |> assign(:kokoro_voices, kokoro_voices)
      |> assign(:selected_avatar_voice, "af_bella")
      |> assign(:avatar_voice_settings_open, false)

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
  def handle_event("send", %{"message_input" => message_input}, socket) do
    handle_send_message(socket, message_input)
  end

  @impl true
  def handle_event("change_person", %{"person" => person}, socket) do
    # Reset to default voice for the selected avatar
    default_voice = case person do
      "julia" -> "af_bella"
      "david" -> "am_fenrir"
      _ -> "af_bella"
    end

    socket =
      socket
      |> assign(:selected_person, person)
      |> assign(:selected_avatar_voice, default_voice)
      |> push_event("change_avatar_voice", %{voice: default_voice})

    {:noreply, socket}
  end

  @impl true
  def handle_event("letter", %{"message_input" => message_input}, socket) do
    socket =
      socket
      |> assign(:message_draft, message_input)
      # Clear countdown when user types
      |> assign(:auto_submit_countdown, 0)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_speech", _params, %{assigns: assigns} = socket) do
    cond do
      assigns.speech_listening and not assigns.speech_muted ->
        # Currently listening -> go to muted state
        socket =
          socket
          |> assign(:speech_muted, true)
          |> assign(:auto_submit_countdown, 0)
          |> push_event("mute_listening", %{})

        {:noreply, socket}

      assigns.speech_muted ->
        # Currently muted -> resume listening
        socket =
          socket
          |> assign(:speech_muted, false)
          |> push_event("unmute_listening", %{})

        {:noreply, socket}

      true ->
        # Not listening at all -> start listening
        socket =
          socket
          |> assign(:speech_muted, false)
          |> push_event("start_listening", %{})

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("speech_started", _params, socket) do
    socket =
      socket
      |> assign(:speech_listening, true)
      |> assign(:speech_interim_text, "")
      |> assign(:auto_submit_countdown, 0)
      |> assign(:speech_muted, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_ended", _params, socket) do
    socket =
      socket
      |> assign(:speech_listening, false)
      |> assign(:speech_interim_text, "")

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_muted", _params, socket) do
    socket =
      socket
      |> assign(:speech_muted, true)
      |> assign(:speech_interim_text, "")
      |> assign(:auto_submit_countdown, 0)

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_unmuted", _params, socket) do
    socket =
      socket
      |> assign(:speech_muted, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_speech", _params, socket) do
    socket =
      socket
      |> assign(:speech_listening, false)
      |> assign(:speech_muted, false)
      |> assign(:speech_interim_text, "")
      |> assign(:auto_submit_countdown, 0)
      |> push_event("stop_listening", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_interim", %{"text" => text}, socket) do
    socket =
      socket
      |> assign(:speech_interim_text, text)

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_final", %{"text" => text}, %{assigns: assigns} = socket) do
    # Append the final speech text to the current message draft with proper spacing
    current_text = String.trim(assigns.message_draft)

    new_message =
      if current_text == "", do: String.trim(text), else: "#{current_text} #{String.trim(text)}"

    socket =
      socket
      |> assign(:message_draft, new_message)
      |> assign(:speech_interim_text, "")

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_error", %{"error" => error}, socket) do
    # Handle speech recognition errors gracefully
    error_message =
      case error do
        nil -> "Unknown speech recognition error"
        "" -> "Speech recognition error occurred"
        err when is_binary(err) -> "Speech recognition error: #{err}"
        _ -> "Speech recognition error occurred"
      end

    socket =
      socket
      |> assign(:speech_listening, false)
      |> assign(:speech_muted, false)
      |> assign(:speech_interim_text, "")
      |> assign(:auto_submit_countdown, 0)
      |> put_flash(:error, error_message)

    {:noreply, socket}
  end

  @impl true
  def handle_event("speech_not_supported", _params, socket) do
    socket =
      socket
      |> assign(:speech_supported, false)
      |> put_flash(:error, "Speech recognition is not supported in this browser")

    {:noreply, socket}
  end

  @impl true
  def handle_event("auto_submit_countdown", %{"seconds" => seconds}, socket) do
    # Handle both integer and float values from JavaScript, with better rounding
    rounded_seconds =
      case seconds do
        n when is_integer(n) ->
          max(0, n)

        n when is_float(n) ->
          # Round to 1 decimal place and ensure we don't get negative values
          max(0.0, Float.round(n, 1))

        _ ->
          0
      end

    socket =
      socket
      |> assign(:auto_submit_countdown, rounded_seconds)

    {:noreply, socket}
  end

  @impl true
  def handle_event("auto_submit_speech", _params, %{assigns: assigns} = socket) do
    # Combine both message draft and speech interim text for auto-submit
    message_text = String.trim("#{assigns.message_draft} #{assigns.speech_interim_text}")

    if message_text != "" and not assigns.dialog_input_disabled do
      # Use the same logic as the manual "send" event
      handle_send_message(socket, message_text)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_tts", _params, socket) do
    new_auto_speak = not socket.assigns.tts_auto_speak

    socket =
      socket
      |> assign(:tts_auto_speak, new_auto_speak)
      |> put_flash(
        :info,
        if(new_auto_speak, do: "Auto-speak enabled", else: "Auto-speak disabled")
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("speak_message", %{"text" => text}, socket) do
    socket =
      socket
      |> push_event("speak_text", %{text: text})

    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_tts", _params, socket) do
    socket =
      socket
      |> assign(:tts_speaking, false)
      |> push_event("stop_speech_synthesis", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("tts_started", _params, socket) do
    socket =
      socket
      |> assign(:tts_speaking, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("tts_ended", _params, socket) do
    socket =
      socket
      |> assign(:tts_speaking, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("tts_error", %{"error" => error}, socket) do
    socket =
      socket
      |> assign(:tts_speaking, false)
      |> put_flash(:error, "Text-to-speech error: #{error}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("voices_loaded", %{"voices" => voices}, socket) do
    socket =
      socket
      |> assign(:available_voices, voices)

    {:noreply, socket}
  end

  @impl true
  def handle_event("voice_selected", params, socket) do
    socket =
      socket
      |> assign(:selected_voice, params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("voice_changed", params, socket) do
    socket =
      socket
      |> assign(:selected_voice, params)
      |> put_flash(:info, "Voice changed to #{params["name"]}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_voice", %{"voice_uri" => voice_uri}, socket) do
    socket =
      socket
      |> push_event("change_voice", %{voiceURI: voice_uri})

    {:noreply, socket}
  end

  @impl true
  def handle_event("test_voice", %{"voice_uri" => voice_uri} = params, socket) do
    test_text = Map.get(params, "text", "Hello! This is a voice test.")

    socket =
      socket
      |> assign(:voice_testing, true)
      |> push_event("test_voice", %{voiceURI: voice_uri, text: test_text})

    {:noreply, socket}
  end

  @impl true
  def handle_event("voice_test_started", _params, socket) do
    socket =
      socket
      |> assign(:voice_testing, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("voice_test_ended", _params, socket) do
    socket =
      socket
      |> assign(:voice_testing, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("voice_test_error", %{"error" => error}, socket) do
    socket =
      socket
      |> assign(:voice_testing, false)
      |> put_flash(:error, "Voice test error: #{error}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_voice_settings", _params, socket) do
    socket =
      socket
      |> assign(:voice_settings_open, not socket.assigns.voice_settings_open)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_avatar_voice_settings", _params, socket) do
    {:noreply, assign(socket, :avatar_voice_settings_open, not socket.assigns.avatar_voice_settings_open)}
  end

  @impl true
  def handle_event("change_avatar_voice", %{"voice_id" => voice_id}, socket) do
    socket =
      socket
      |> assign(:selected_avatar_voice, voice_id)
      |> push_event("change_avatar_voice", %{voice: voice_id})

    {:noreply, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(other_event: event)
    IO.inspect(other_params: params)
    {:noreply, socket}
  end

  # Helper function to handle message sending (extracted from send event)
  defp handle_send_message(socket, message_input) do
    assigns = socket.assigns

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
      Ollama.chat(liveview_pid, prompt_messages)
    end)

    socket =
      socket
      |> assign(:messages, messages)
      |> assign(:dialog_input, %{"input_message" => ""})
      |> assign(:conversation, conversation)
      |> assign(:dialog_input_disabled, true)
      |> assign(:message_draft, "")
      |> assign(:speech_interim_text, "")
      |> assign(:speech_listening, false)
      |> assign(:auto_submit_countdown, 0)
      |> push_patch(to: ~p"/chat/#{conversation.id}")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:token, token}, socket) do
    socket =
      socket
      |> assign(:bot_streaming, true)
      |> assign(:streaming_tokens, socket.assigns.streaming_tokens <> token)
      |> push_event("token_mouth_animation", %{token: token})

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

    # Auto-speak bot response if enabled - route through 3D avatar
    socket =
      if assigns.tts_auto_speak and assigns.tts_enabled do
        socket |> push_event("speak_avatar", %{text: full_response})
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(other, socket) do
    IO.inspect(handle_info_other: other)
    {:noreply, socket}
  end
end
