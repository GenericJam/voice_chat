defmodule Chat.AudioTiming do
  @moduledoc """
  Calculates timing information for audio playback and word synchronization.
  """

  @doc """
  Calculates the duration of WAV audio data in milliseconds.

  ## Parameters
    - audio_data: Binary WAV file data
    - sample_rate: Sample rate in Hz (default: 24000)

  ## Returns
    Duration in milliseconds as a float
  """
  def calculate_duration(audio_data, sample_rate \\ 24000) do
    # WAV header is 44 bytes, rest is audio data
    # For 16-bit mono audio: bytes / 2 = samples
    # Duration = samples / sample_rate
    audio_bytes = byte_size(audio_data) - 44
    samples = audio_bytes / 2  # 16-bit audio = 2 bytes per sample
    duration_seconds = samples / sample_rate
    duration_seconds * 1000  # Convert to milliseconds
  end

  @doc """
  Splits text into words with timing information based on audio duration.

  ## Parameters
    - text: The text to split
    - duration_ms: Total audio duration in milliseconds

  ## Returns
    List of maps with word timing: `[%{word: String.t(), start_ms: float(), duration_ms: float()}, ...]`

  ## Examples

      iex> Chat.AudioTiming.calculate_word_timings("Hello world!", 2000.0)
      [
        %{word: "Hello", start_ms: 0.0, duration_ms: 1000.0},
        %{word: "world!", start_ms: 1000.0, duration_ms: 1000.0}
      ]
  """
  def calculate_word_timings(text, duration_ms) do
    words = String.split(text, ~r/\s+/, trim: true)
    word_count = length(words)

    if word_count == 0 do
      []
    else
      time_per_word = duration_ms / word_count

      words
      |> Enum.with_index()
      |> Enum.map(fn {word, index} ->
        %{
          word: word,
          start_ms: index * time_per_word,
          duration_ms: time_per_word
        }
      end)
    end
  end
end
