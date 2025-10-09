defmodule ChatWeb.Avatar3Live.Index do
  use ChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Avatar Chat")
      |> assign(:selected_person, "julia")
      |> assign(:speaking, false)
      |> assign(:messages, [])
      |> assign(:message_input, "")
      |> assign(:speech_listening, false)
      |> assign(:speech_supported, true)
      |> assign(:speech_interim_text, "")
      |> assign(:speech_muted, false)
      |> assign(:tts_speaking, false)
      |> assign(:tts_auto_speak, true)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_person", %{"person" => person}, socket) do
    {:noreply, assign(socket, :selected_person, person)}
  end

  @impl true
  def handle_event("voices_loaded", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("voice_selected", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("speak", _params, socket) do
    {:noreply, assign(socket, :speaking, true)}
  end

  @impl true
  def handle_event("speaking_complete", _params, socket) do
    {:noreply, assign(socket, :speaking, false)}
  end

  @impl true
  def handle_event("send_message", %{"message_input" => message_text}, socket) do
    if String.trim(message_text) != "" do
      # Add user message
      user_message = %{
        text: message_text,
        from: "user",
        timestamp: DateTime.utc_now()
      }

      # Simple echo response for now
      bot_message = %{
        text: "You said: #{message_text}",
        from: "bot",
        timestamp: DateTime.utc_now()
      }

      socket =
        socket
        |> assign(:messages, socket.assigns.messages ++ [user_message, bot_message])
        |> assign(:message_input, "")
        |> assign(:speech_interim_text, "")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Speech Recognition Events
  @impl true
  def handle_event("toggle_speech", _params, socket) do
    cond do
      socket.assigns.speech_muted ->
        {:noreply, assign(socket, speech_muted: false)}

      socket.assigns.speech_listening ->
        {:noreply, assign(socket, speech_muted: true)}

      true ->
        {:noreply, assign(socket, speech_listening: true)}
    end
  end

  @impl true
  def handle_event("speech_interim", %{"text" => text}, socket) do
    {:noreply, assign(socket, speech_interim_text: text)}
  end

  @impl true
  def handle_event("speech_final", %{"text" => text}, socket) do
    current_input = socket.assigns.message_input
    new_input = String.trim(current_input <> " " <> text)

    {:noreply, assign(socket, message_input: new_input, speech_interim_text: "")}
  end

  @impl true
  def handle_event("speech_started", _params, socket) do
    {:noreply, assign(socket, speech_listening: true)}
  end

  @impl true
  def handle_event("speech_ended", _params, socket) do
    {:noreply, assign(socket, speech_listening: false)}
  end

  @impl true
  def handle_event("speech_muted", _params, socket) do
    {:noreply, assign(socket, speech_muted: true)}
  end

  @impl true
  def handle_event("speech_unmuted", _params, socket) do
    {:noreply, assign(socket, speech_muted: false)}
  end

  @impl true
  def handle_event("speech_not_supported", _params, socket) do
    {:noreply, assign(socket, speech_supported: false)}
  end

  # TTS Events
  @impl true
  def handle_event("toggle_tts", _params, socket) do
    {:noreply, assign(socket, tts_auto_speak: !socket.assigns.tts_auto_speak)}
  end

  @impl true
  def handle_event("tts_started", _params, socket) do
    {:noreply, assign(socket, tts_speaking: true)}
  end

  @impl true
  def handle_event("tts_ended", _params, socket) do
    {:noreply, assign(socket, tts_speaking: false)}
  end

  @impl true
  def handle_event("stop_tts", _params, socket) do
    {:noreply, socket}
  end
end
