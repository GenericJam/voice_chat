defmodule Chat.TextChunker do
  @moduledoc """
  Handles chunking of streaming text into punctuation-based groups for progressive TTS.
  """

  defstruct buffer: ""

  @doc """
  Creates a new TextChunker

  ## Examples

      iex> Chat.TextChunker.new()
      %Chat.TextChunker{buffer: ""}
  """
  def new do
    %__MODULE__{}
  end

  @doc """
  Adds a token to the chunker and returns any complete chunks that are ready.

  Chunks are returned when the buffer contains text ending with sentence punctuation (.!?)
  The last chunk is returned when `finalize: true` is passed.

  ## Parameters
    - chunker: The TextChunker struct
    - token: The text token to add
    - opts: Options (currently unused, kept for API compatibility)

  ## Returns
    `{updated_chunker, list_of_ready_chunks}`

  ## Examples

      iex> chunker = Chat.TextChunker.new()
      iex> {chunker, chunks} = Chat.TextChunker.add_token(chunker, "Hello ")
      iex> chunks
      []
      iex> {chunker, chunks} = Chat.TextChunker.add_token(chunker, "world! ")
      iex> chunks
      ["Hello world!"]
  """
  def add_token(chunker, token, _opts \\ []) do
    # Add token to buffer
    updated_buffer = chunker.buffer <> token

    # Extract complete chunks (those ending with punctuation)
    {remaining_buffer, new_chunks} = extract_chunks(updated_buffer)

    updated_chunker = %{chunker | buffer: remaining_buffer}

    {updated_chunker, new_chunks}
  end

  @doc """
  Finalizes the chunker and returns any remaining text as the last chunk.

  ## Examples

      iex> chunker = Chat.TextChunker.new()
      iex> {chunker, _} = Chat.TextChunker.add_token(chunker, "Hello ")
      iex> {chunker, _} = Chat.TextChunker.add_token(chunker, "world")
      iex> Chat.TextChunker.finalize(chunker)
      {%Chat.TextChunker{buffer: ""}, ["Hello world"]}
  """
  def finalize(chunker) do
    remaining = String.trim(chunker.buffer)

    chunks = if remaining == "", do: [], else: [remaining]

    updated_chunker = %{chunker | buffer: ""}

    {updated_chunker, chunks}
  end

  # Private functions

  defp extract_chunks(buffer) do
    # Split on sentence-ending punctuation marks only (.!?)
    # Match text followed by punctuation and optional whitespace
    chunks = Regex.split(~r/([.!?]+\s*)/, buffer, include_captures: true, trim: true)

    # Process chunks - combine text with following punctuation
    {remaining, completed} = process_chunks(chunks, "", [])

    {remaining, Enum.reverse(completed)}
  end

  defp process_chunks([], accumulator, completed) do
    # Return any remaining text in accumulator
    {accumulator, completed}
  end

  defp process_chunks([chunk | rest], accumulator, completed) do
    cond do
      # If chunk is sentence-ending punctuation, attach it to accumulator and complete the chunk
      Regex.match?(~r/^[.!?]+\s*$/, chunk) ->
        completed_chunk = String.trim(accumulator <> chunk)
        process_chunks(rest, "", [completed_chunk | completed])

      # If chunk is text, add to accumulator
      true ->
        process_chunks(rest, accumulator <> chunk, completed)
    end
  end
end
