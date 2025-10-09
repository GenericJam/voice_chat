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
    # Use the persistent TTS server for faster synthesis
    Chat.TTSServer.synthesize(text, voice)
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
