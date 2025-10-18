defmodule Chat.AudioTimingTest do
  use ExUnit.Case, async: true

  alias Chat.AudioTiming

  describe "calculate_duration/2" do
    test "calculates duration for standard WAV audio" do
      # Create mock WAV data: 44 byte header + audio samples
      # For 1 second at 24000 Hz, 16-bit mono: 24000 samples = 48000 bytes
      header = :binary.copy(<<0>>, 44)
      audio_samples = :binary.copy(<<0>>, 48000)
      audio_data = header <> audio_samples

      duration = AudioTiming.calculate_duration(audio_data, 24000)

      # Should be approximately 1000ms (1 second)
      assert_in_delta duration, 1000.0, 0.1
    end

    test "calculates duration for half second audio" do
      header = :binary.copy(<<0>>, 44)
      # 0.5 seconds at 24000 Hz = 12000 samples = 24000 bytes
      audio_samples = :binary.copy(<<0>>, 24000)
      audio_data = header <> audio_samples

      duration = AudioTiming.calculate_duration(audio_data, 24000)

      assert_in_delta duration, 500.0, 0.1
    end

    test "handles different sample rates" do
      header = :binary.copy(<<0>>, 44)
      # 1 second at 48000 Hz = 48000 samples = 96000 bytes
      audio_samples = :binary.copy(<<0>>, 96000)
      audio_data = header <> audio_samples

      duration = AudioTiming.calculate_duration(audio_data, 48000)

      assert_in_delta duration, 1000.0, 0.1
    end

    test "uses default sample rate of 24000" do
      header = :binary.copy(<<0>>, 44)
      audio_samples = :binary.copy(<<0>>, 48000)
      audio_data = header <> audio_samples

      duration = AudioTiming.calculate_duration(audio_data)

      # Should use default 24000 sample rate
      assert_in_delta duration, 1000.0, 0.1
    end

    test "handles empty audio data (header only)" do
      # Just the 44-byte header, no audio samples
      audio_data = :binary.copy(<<0>>, 44)

      duration = AudioTiming.calculate_duration(audio_data)

      # Duration should be 0
      assert duration == 0.0
    end
  end

  describe "calculate_word_timings/2" do
    test "splits text into words with even timing" do
      text = "Hello world"
      duration_ms = 2000.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert length(result) == 2
      assert [
        %{word: "Hello", start_ms: 0.0, duration_ms: 1000.0},
        %{word: "world", start_ms: 1000.0, duration_ms: 1000.0}
      ] == result
    end

    test "handles single word" do
      text = "Hello"
      duration_ms = 1000.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert [
        %{word: "Hello", start_ms: 0.0, duration_ms: 1000.0}
      ] == result
    end

    test "handles multiple spaces between words" do
      text = "Hello    world    test"
      duration_ms = 3000.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert length(result) == 3
      assert [
        %{word: "Hello", start_ms: 0.0, duration_ms: 1000.0},
        %{word: "world", start_ms: 1000.0, duration_ms: 1000.0},
        %{word: "test", start_ms: 2000.0, duration_ms: 1000.0}
      ] == result
    end

    test "handles punctuation attached to words" do
      text = "Hello, world! How are you?"
      duration_ms = 5000.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert length(result) == 5
      # Punctuation stays with words
      assert Enum.at(result, 0).word == "Hello,"
      assert Enum.at(result, 1).word == "world!"
    end

    test "returns empty list for empty text" do
      result = AudioTiming.calculate_word_timings("", 1000.0)

      assert result == []
    end

    test "returns empty list for whitespace-only text" do
      result = AudioTiming.calculate_word_timings("   \n\t  ", 1000.0)

      assert result == []
    end

    test "calculates correct timing for many words" do
      text = "One two three four five six seven eight nine ten"
      duration_ms = 10000.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert length(result) == 10
      # Each word should get 1000ms
      assert Enum.all?(result, fn w -> w.duration_ms == 1000.0 end)
      # Start times should be evenly spaced
      assert Enum.at(result, 0).start_ms == 0.0
      assert Enum.at(result, 5).start_ms == 5000.0
      assert Enum.at(result, 9).start_ms == 9000.0
    end

    test "handles short duration with many words" do
      text = "Quick brown fox"
      duration_ms = 300.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert length(result) == 3
      # Each word gets 100ms
      assert Enum.all?(result, fn w -> w.duration_ms == 100.0 end)
    end

    test "handles newlines and tabs as whitespace" do
      text = "Hello\nworld\ttest"
      duration_ms = 3000.0

      result = AudioTiming.calculate_word_timings(text, duration_ms)

      assert length(result) == 3
      assert Enum.map(result, & &1.word) == ["Hello", "world", "test"]
    end
  end
end
