defmodule ChatWeb.TTSController do
  use ChatWeb, :controller

  def synthesize(conn, params) do
    IO.puts("[TTS Controller] Received TTS request")
    IO.puts("[TTS Controller] Request params: #{inspect(params)}")

    # Extract text from multiple formats
    text = case params do
      %{"input" => %{"text" => text}} when is_binary(text) -> text
      %{"text" => text} when is_binary(text) -> text
      _ -> "Hello, I am a talking avatar powered by Kokoro TTS"
    end

    # Extract voice parameter
    voice = case params do
      %{"voice" => voice} when is_binary(voice) -> voice
      _ -> "af_sarah"
    end

    IO.puts("[TTS Controller] Using text: #{String.slice(text, 0, 50)}...")
    IO.puts("[TTS Controller] Using voice: #{voice}")

    case Chat.TTS.text_to_speech(text, voice) do
      {:ok, %{audio_data: audio_data, sample_rate: sample_rate}} ->
        IO.puts("[TTS Controller] TTS generation successful, audio size: #{byte_size(audio_data)} bytes")

        # Split text into words for subtitle timing
        words = String.split(text, ~r/\s+/, trim: true)

        # Return response with base64-encoded audio and word data
        audio_base64 = Base.encode64(audio_data)

        response = %{
          audio: audio_base64,
          audioContent: audio_base64,  # Keep for backward compatibility
          words: words,
          wtimes: [],  # Word start times (not available from Kokoro)
          wdurations: []  # Word durations (not available from Kokoro)
        }

        conn
        |> put_resp_content_type("application/json")
        |> json(response)

      {:error, reason} ->
        IO.puts("[TTS Controller] TTS generation failed: #{inspect(reason)}")

        conn
        |> put_status(500)
        |> json(%{error: "TTS generation failed: #{inspect(reason)}"})
    end
  end
end
