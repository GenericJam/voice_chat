defmodule ChatWeb.RobotDebugLive.Index do
  use ChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Robot Debug")
      |> assign(:tts_speaking, false)
      |> assign(:available_voices, %{})
      |> assign(:selected_voice, nil)
      |> assign(:voice_testing, false)
      |> assign(:voice_settings_open, false)
      |> assign(:test_phrase, "The quick brown fox jumps over the lazy dog")
      |> assign(:speech_rate, 0.5)

    {:ok, socket}
  end

  @impl true
  def handle_event("speak_test_phrase", _params, socket) do
    socket =
      socket
      |> push_event("speak_text", %{
        text: socket.assigns.test_phrase,
        rate: socket.assigns.speech_rate
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("speak_terminator", _params, socket) do
    socket =
      socket
      |> push_event("speak_text", %{
        text: socket.assigns.test_phrase,
        rate: socket.assigns.speech_rate,
        target: "terminator"
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("speak_avatar", _params, socket) do
    socket =
      socket
      |> push_event("speak_text", %{
        text: socket.assigns.test_phrase,
        rate: socket.assigns.speech_rate,
        target: "avatar"
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_speech_rate", %{"rate" => rate}, socket) do
    {rate_float, _} = Float.parse(rate)
    {:noreply, assign(socket, :speech_rate, rate_float)}
  end

  @impl true
  def handle_event("tts_started", _params, socket) do
    {:noreply, assign(socket, :tts_speaking, true)}
  end

  @impl true
  def handle_event("tts_ended", _params, socket) do
    {:noreply, assign(socket, :tts_speaking, false)}
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
    {:noreply, assign(socket, :available_voices, voices)}
  end

  @impl true
  def handle_event("voice_selected", params, socket) do
    {:noreply, assign(socket, :selected_voice, params)}
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
    {:noreply, push_event(socket, "change_voice", %{voiceURI: voice_uri})}
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
    {:noreply, assign(socket, :voice_testing, true)}
  end

  @impl true
  def handle_event("voice_test_ended", _params, socket) do
    {:noreply, assign(socket, :voice_testing, false)}
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
    {:noreply, assign(socket, :voice_settings_open, not socket.assigns.voice_settings_open)}
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
  def handle_event("mouth_animation", _params, socket) do
    # This event is sent from JS but we don't need to do anything server-side
    # The animation is handled entirely in the browser
    {:noreply, socket}
  end
end
