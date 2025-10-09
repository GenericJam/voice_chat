defmodule ChatWeb.AvatarLive.Index do
  use ChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Avatar with Kokoro TTS")
      |> assign(:tts_speaking, false)
      |> assign(:test_phrase, "Hello, I am a talking avatar powered by Kokoro TTS")

    {:ok, socket}
  end

  @impl true
  def handle_event("speak_with_kokoro", _params, socket) do
    IO.puts("[Backend] speak_with_kokoro event received")
    IO.puts("[Backend] Instructing frontend to manually fetch TTS and use speakAudio()")

    # Use manual fetch approach with speakAudio
    socket =
      socket
      |> assign(:tts_speaking, true)
      |> push_event("speak_with_tts_manual", %{
        text: socket.assigns.test_phrase
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("test_audio_only", _params, socket) do
    IO.puts("[Backend] test_audio_only event received")

    # Generate TTS audio using Kokoro
    case Chat.TTS.text_to_speech(socket.assigns.test_phrase, "af_sarah") do
      {:ok, %{audio_data: audio_data}} ->
        IO.puts("[Backend] TTS generation successful for audio test")

        # Base64 encode the audio data
        audio_base64 = Base.encode64(audio_data)

        # Send to frontend to play directly
        socket =
          socket
          |> assign(:tts_speaking, true)
          |> push_event("play_audio_only", %{audioData: audio_base64})

        IO.puts("[Backend] Audio test event sent")
        {:noreply, socket}

      {:error, reason} ->
        IO.puts("[Backend] TTS generation failed: #{inspect(reason)}")
        socket =
          socket
          |> put_flash(:error, "TTS generation failed: #{inspect(reason)}")

        {:noreply, socket}
    end
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
      |> put_flash(:error, "Audio playback error: #{error}")

    {:noreply, socket}
  end
end
