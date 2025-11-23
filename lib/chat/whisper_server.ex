defmodule Chat.WhisperServer do
  @moduledoc """
  GenServer that holds the Whisper serving instance and processes audio transcriptions.
  """
  use GenServer

  # Client API

  def start_link(serving) do
    GenServer.start_link(__MODULE__, serving, name: __MODULE__)
  end

  @doc """
  Transcribe audio data. Audio should be a 1D tensor or a list of normalized floats [-1.0, 1.0].
  Returns {:ok, text} or {:error, reason}
  """
  def transcribe(audio_data) do
    GenServer.call(__MODULE__, {:transcribe, audio_data}, 30_000)
  end

  # Server Callbacks

  @impl true
  def init(serving) do
    {:ok, %{serving: serving}}
  end

  @impl true
  def handle_call({:transcribe, audio_data}, _from, state) do
    try do
      tensor_start = System.monotonic_time(:millisecond)
      # Convert to 1D tensor if it's a list
      audio_tensor = case audio_data do
        %Nx.Tensor{} = tensor ->
          ensure_1d(tensor)
        list when is_list(list) ->
          Nx.tensor(list, type: :f32)
        _ ->
          raise ArgumentError, "Invalid audio data format"
      end
      tensor_end = System.monotonic_time(:millisecond)

      IO.puts("   ⏱️  Tensor creation: #{tensor_end - tensor_start}ms (shape: #{inspect(Nx.shape(audio_tensor))})")

      # Run transcription
      serving_start = System.monotonic_time(:millisecond)
      result = Nx.Serving.run(state.serving, audio_tensor)
      serving_end = System.monotonic_time(:millisecond)

      IO.puts("   ⏱️  Nx.Serving.run (model inference): #{serving_end - serving_start}ms")

      # Extract text from result
      text = case result do
        %{chunks: [%{text: text} | _]} -> text
        %{chunks: []} -> ""
        _ -> ""
      end

      {:reply, {:ok, text}, state}
    rescue
      error ->
        IO.puts("❌ Error in WhisperServer: #{Exception.message(error)}")
        {:reply, {:error, Exception.message(error)}, state}
    end
  end

  # Helper to ensure tensor is 1D
  defp ensure_1d(tensor) do
    case Nx.shape(tensor) do
      {_} -> tensor
      {1, n} -> Nx.reshape(tensor, {n})
      _ -> raise ArgumentError, "Audio tensor must be 1D, got shape: #{inspect(Nx.shape(tensor))}"
    end
  end
end
