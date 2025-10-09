defmodule Chat.TTS do
  @moduledoc """
  Text-to-speech using Kokoro TTS via PythonX
  """

  @doc """
  Generate speech audio from text using Kokoro TTS

  ## Parameters
    - text: The text to convert to speech
    - voice: Voice to use (default: "af_sarah")

  ## Returns
    - `{:ok, %{audio_data: binary(), sample_rate: integer(), format: String.t()}}`
    - `{:error, term()}`

  ## Examples

      iex> Chat.TTS.text_to_speech("Hello world")
      {:ok, %{audio_data: <<...>>, sample_rate: 24000, format: "wav"}}
  """
  def text_to_speech(text, voice \\ "af_sarah") do
    # Get model paths relative to the app root
    app_dir = Application.app_dir(:chat)
    model_path = Path.join([app_dir, "priv", "models", "kokoro-v1.0.onnx"])
    voices_path = Path.join([app_dir, "priv", "models", "voices-v1.0.bin"])

    # Python code to execute - directly inline the TTS logic
    python_code = """
    import kokoro_onnx
    import io
    import soundfile as sf

    # Convert all inputs from bytes to strings (they come as bytes from Elixir via PythonX)
    model_path_str = model_path.decode('utf-8') if isinstance(model_path, bytes) else str(model_path)
    voices_path_str = voices_path.decode('utf-8') if isinstance(voices_path, bytes) else str(voices_path)
    text_str = text.decode('utf-8') if isinstance(text, bytes) else str(text)
    voice_str = voice.decode('utf-8') if isinstance(voice, bytes) else str(voice)

    # Initialize Kokoro
    kokoro = kokoro_onnx.Kokoro(
        model_path=model_path_str,
        voices_path=voices_path_str
    )

    # Generate audio samples
    samples, sample_rate = kokoro.create(text_str, voice=voice_str, speed=1.0)

    # Convert to WAV format in memory
    audio_buffer = io.BytesIO()
    sf.write(audio_buffer, samples, sample_rate, format='WAV', subtype='PCM_16')
    audio_buffer.seek(0)
    audio_bytes = audio_buffer.read()

    # Return as dict
    result = {
        'audio_data': audio_bytes,
        'sample_rate': sample_rate,
        'format': 'wav'
    }
    result
    """

    # Pass text, voice, and model paths as global variables to Python
    globals = %{
      "text" => text,
      "voice" => voice,
      "model_path" => model_path,
      "voices_path" => voices_path
    }

    case Pythonx.eval(python_code, globals) do
      {result, _globals} ->
        # Convert Python object to Elixir data
        elixir_result = Pythonx.decode(result)

        {:ok, %{
          audio_data: elixir_result["audio_data"],
          sample_rate: elixir_result["sample_rate"],
          format: elixir_result["format"]
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Save generated speech to a WAV file

  ## Parameters
    - text: The text to convert to speech
    - output_path: Path where to save the WAV file
    - voice: Voice to use (default: "af_sarah")

  ## Returns
    - `:ok` on success
    - `{:error, term()}` on failure
  """
  def text_to_speech_file(text, output_path, voice \\ "af_sarah") do
    case text_to_speech(text, voice) do
      {:ok, %{audio_data: audio_data}} ->
        File.write(output_path, audio_data)

      error ->
        error
    end
  end
end
