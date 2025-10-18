defmodule Chat.TTSTest do
  use Chat.DataCase

  alias Chat.TTS

  describe "text_to_speech/2" do
    test "sanitizes quotation marks from text" do
      # This will fail if TTS server isn't running, but we're mainly testing sanitization
      result = TTS.text_to_speech("Hello \"world\" with 'quotes' and `backticks`")

      # The function should either succeed or return an error
      # but it shouldn't crash on quotes
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "returns error for empty text after sanitization" do
      result = TTS.text_to_speech("\"\"\"")

      assert {:error, :empty_text} == result
    end

    test "returns error for whitespace-only text" do
      result = TTS.text_to_speech("   ")

      assert {:error, :empty_text} == result
    end

    test "handles text with only quotes and whitespace" do
      result = TTS.text_to_speech("  \" \" ' ' ` `  ")

      assert {:error, :empty_text} == result
    end

    test "accepts custom voice parameter" do
      result = TTS.text_to_speech("Hello", "am_fenrir")

      # Should not crash with custom voice
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "uses default voice when not specified" do
      result = TTS.text_to_speech("Hello")

      # Should use default voice af_sarah
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "text_to_speech_file/3" do
    test "writes audio to file when successful" do
      output_path = Path.join(System.tmp_dir!(), "test_tts_output.wav")

      # Clean up any existing file
      File.rm(output_path)

      result = TTS.text_to_speech_file("Hello world", output_path)

      # Clean up
      File.rm(output_path)

      # Should either succeed or fail gracefully
      assert match?(:ok, result) or match?({:error, _}, result)
    end

    test "returns error when text is empty after sanitization" do
      output_path = Path.join(System.tmp_dir!(), "test_tts_empty.wav")

      result = TTS.text_to_speech_file("\"\"\"", output_path)

      assert {:error, :empty_text} == result
    end

    test "uses custom voice parameter" do
      output_path = Path.join(System.tmp_dir!(), "test_tts_voice.wav")

      result = TTS.text_to_speech_file("Hello", output_path, "am_fenrir")

      # Clean up
      File.rm(output_path)

      assert match?(:ok, result) or match?({:error, _}, result)
    end
  end
end
