defmodule ChatWeb.TTSController do
  use ChatWeb, :controller

  def synthesize(conn, params) do
    IO.puts("[TTS Controller] Received TTS request")
    IO.puts("[TTS Controller] Request params: #{inspect(params)}")

    # Extract text from Google TTS-style format: {"input": {"text": "..."}}
    text = case params do
      %{"input" => %{"text" => text}} when is_binary(text) -> text
      %{"text" => text} when is_binary(text) -> text
      _ -> "Hello, I am a talking avatar powered by Kokoro TTS"
    end

    IO.puts("[TTS Controller] Using text: #{String.slice(text, 0, 50)}...")

    # Use default Kokoro voice (we ignore Google voice parameters)
    voice = "af_sarah"

    case Chat.TTS.text_to_speech(text, voice) do
      {:ok, %{audio_data: audio_data, sample_rate: sample_rate}} ->
        IO.puts("[TTS Controller] TTS generation successful, audio size: #{byte_size(audio_data)} bytes")

        # Return Google TTS-style response with base64-encoded audio
        audio_base64 = Base.encode64(audio_data)

        conn
        |> put_resp_content_type("application/json")
        |> json(%{audioContent: audio_base64})

      {:error, reason} ->
        IO.puts("[TTS Controller] TTS generation failed: #{inspect(reason)}")

        conn
        |> put_status(500)
        |> json(%{error: "TTS generation failed: #{inspect(reason)}"})
    end
  end
end
