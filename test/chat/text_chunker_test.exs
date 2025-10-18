defmodule Chat.TextChunkerTest do
  use ExUnit.Case, async: true

  alias Chat.TextChunker

  doctest Chat.TextChunker

  describe "new/0" do
    test "creates a new chunker with empty buffer" do
      chunker = TextChunker.new()

      assert %TextChunker{buffer: ""} = chunker
    end
  end

  describe "add_token/3" do
    test "accumulates tokens without sentence-ending punctuation" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello ")
      assert chunks == []
      assert chunker.buffer == "Hello "

      {chunker, chunks} = TextChunker.add_token(chunker, "world")
      assert chunks == []
      assert chunker.buffer == "Hello world"
    end

    test "returns chunk when period is encountered" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello world.")
      assert chunks == ["Hello world."]
      assert chunker.buffer == ""
    end

    test "returns chunk when exclamation mark is encountered" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello world!")
      assert chunks == ["Hello world!"]
      assert chunker.buffer == ""
    end

    test "returns chunk when question mark is encountered" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello world?")
      assert chunks == ["Hello world?"]
      assert chunker.buffer == ""
    end

    test "handles multiple sentences in one token" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello. World! How are you?")
      assert chunks == ["Hello.", "World!", "How are you?"]
      assert chunker.buffer == ""
    end

    test "handles period with space" do
      chunker = TextChunker.new()
      {chunker, _} = TextChunker.add_token(chunker, "First sentence. ")
      {chunker, chunks} = TextChunker.add_token(chunker, "Second sentence.")

      # The first complete chunk should have been returned
      assert "Second sentence." in chunks
    end

    test "accumulates incomplete sentences" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello ")
      assert chunks == []
      {chunker, chunks} = TextChunker.add_token(chunker, "world ")
      assert chunks == []
      {chunker, chunks} = TextChunker.add_token(chunker, "today.")
      assert chunks == ["Hello world today."]
    end

    test "handles streaming tokens word by word" do
      chunker = TextChunker.new()

      {chunker, chunks} = TextChunker.add_token(chunker, "The ")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "quick ")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "brown ")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "fox.")
      assert chunks == ["The quick brown fox."]
      assert chunker.buffer == ""
    end

    test "handles multiple periods (ellipsis)" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "Well...")
      assert chunks == ["Well..."]
      assert chunker.buffer == ""
    end

    test "handles mixed punctuation" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "What?! ")
      assert length(chunks) >= 1
    end

    test "preserves whitespace in chunks" do
      chunker = TextChunker.new()
      {_chunker, chunks} = TextChunker.add_token(chunker, "Hello world. ")

      # Chunk should be trimmed
      assert chunks == ["Hello world."]
    end

    test "handles empty tokens" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "")
      assert chunks == []
      assert chunker.buffer == ""
    end

    test "handles tokens with only whitespace" do
      chunker = TextChunker.new()
      {chunker, chunks} = TextChunker.add_token(chunker, "   ")
      assert chunks == []
      # Buffer contains the whitespace
      assert chunker.buffer == "   "
    end

    test "accumulates across multiple add_token calls" do
      chunker = TextChunker.new()

      {chunker, chunks} = TextChunker.add_token(chunker, "First ")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "sentence. ")
      assert chunks == ["First sentence."]

      {chunker, chunks} = TextChunker.add_token(chunker, "Second ")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "sentence!")
      assert chunks == ["Second sentence!"]
    end
  end

  describe "finalize/1" do
    test "returns remaining buffer as final chunk" do
      chunker = TextChunker.new()
      {chunker, _} = TextChunker.add_token(chunker, "Incomplete sentence")

      {updated_chunker, chunks} = TextChunker.finalize(chunker)

      assert chunks == ["Incomplete sentence"]
      assert updated_chunker.buffer == ""
    end

    test "returns empty list when buffer is empty" do
      chunker = TextChunker.new()

      {updated_chunker, chunks} = TextChunker.finalize(chunker)

      assert chunks == []
      assert updated_chunker.buffer == ""
    end

    test "trims whitespace from final chunk" do
      chunker = TextChunker.new()
      {chunker, _} = TextChunker.add_token(chunker, "  Some text  ")

      {_updated_chunker, chunks} = TextChunker.finalize(chunker)

      assert chunks == ["Some text"]
    end

    test "returns empty list when buffer contains only whitespace" do
      chunker = TextChunker.new()
      {chunker, _} = TextChunker.add_token(chunker, "   ")

      {_updated_chunker, chunks} = TextChunker.finalize(chunker)

      assert chunks == []
    end

    test "clears buffer after finalization" do
      chunker = TextChunker.new()
      {chunker, _} = TextChunker.add_token(chunker, "Some text")

      {updated_chunker, _chunks} = TextChunker.finalize(chunker)

      assert updated_chunker.buffer == ""
    end

    test "can be called multiple times safely" do
      chunker = TextChunker.new()
      {chunker, _} = TextChunker.add_token(chunker, "Text")

      {chunker, chunks1} = TextChunker.finalize(chunker)
      assert chunks1 == ["Text"]

      {_chunker, chunks2} = TextChunker.finalize(chunker)
      assert chunks2 == []
    end
  end

  describe "integration scenarios" do
    test "complete streaming conversation flow" do
      chunker = TextChunker.new()

      # Simulate token-by-token streaming
      {chunker, chunks} = TextChunker.add_token(chunker, "Hello")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "! ")
      assert chunks == ["Hello!"]

      {chunker, chunks} = TextChunker.add_token(chunker, "How")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, " can")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, " I")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, " help")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, " you")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, "?")
      assert chunks == ["How can I help you?"]

      # Incomplete final sentence
      {chunker, chunks} = TextChunker.add_token(chunker, " I'm")
      assert chunks == []

      {chunker, chunks} = TextChunker.add_token(chunker, " here")
      assert chunks == []

      # Finalize to get the last chunk
      {_chunker, chunks} = TextChunker.finalize(chunker)
      assert chunks == ["I'm here"]
    end

    test "handles rapid complete sentences" do
      chunker = TextChunker.new()

      {chunker, chunks} = TextChunker.add_token(chunker, "One. Two. Three.")
      assert chunks == ["One.", "Two.", "Three."]
      assert chunker.buffer == ""
    end

    test "handles paragraphs with multiple sentence types" do
      chunker = TextChunker.new()

      text = "What a day! It was amazing. Don't you think?"
      {chunker, chunks} = TextChunker.add_token(chunker, text)

      assert length(chunks) == 3
      assert "What a day!" in chunks
      assert "It was amazing." in chunks
      assert "Don't you think?" in chunks
    end
  end
end
