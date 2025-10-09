defmodule Chat.TTSServer do
  @moduledoc """
  GenServer that maintains a persistent Python process with pre-loaded Kokoro TTS model
  for faster synthesis.
  """
  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Generate speech from text using the persistent Kokoro instance
  """
  def synthesize(text, voice \\ "af_sarah") do
    GenServer.call(__MODULE__, {:synthesize, text, voice}, 30_000)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("[TTSServer] Initializing Kokoro TTS...")

    # Get model paths
    app_dir = Application.app_dir(:chat)
    model_path = Path.join([app_dir, "priv", "models", "kokoro-v1.0.onnx"])
    voices_path = Path.join([app_dir, "priv", "models", "voices-v1.0.bin"])

    # Python code to initialize Kokoro once
    init_code = """
    import kokoro_onnx
    import io
    import soundfile as sf

    model_path_str = model_path.decode('utf-8') if isinstance(model_path, bytes) else str(model_path)
    voices_path_str = voices_path.decode('utf-8') if isinstance(voices_path, bytes) else str(voices_path)

    # Initialize Kokoro ONCE - this is expensive
    kokoro = kokoro_onnx.Kokoro(
        model_path=model_path_str,
        voices_path=voices_path_str
    )

    initialized = True
    """

    globals = %{
      "model_path" => model_path,
      "voices_path" => voices_path
    }

    case Pythonx.eval(init_code, globals) do
      {_result, new_globals} ->
        Logger.info("[TTSServer] Kokoro initialized successfully")
        {:ok, %{globals: new_globals}}

      {:error, reason} ->
        Logger.error("[TTSServer] Failed to initialize: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:synthesize, text, voice}, _from, state) do
    # Python code to use the already-initialized kokoro instance
    synth_code = """
    text_str = text.decode('utf-8') if isinstance(text, bytes) else str(text)
    voice_str = voice.decode('utf-8') if isinstance(voice, bytes) else str(voice)

    # Use the pre-loaded kokoro instance
    samples, sample_rate = kokoro.create(text_str, voice=voice_str, speed=1.0)

    # Convert to WAV
    audio_buffer = io.BytesIO()
    sf.write(audio_buffer, samples, sample_rate, format='WAV', subtype='PCM_16')
    audio_buffer.seek(0)
    audio_bytes = audio_buffer.read()

    result = {
        'audio_data': audio_bytes,
        'sample_rate': sample_rate,
        'format': 'wav'
    }
    result
    """

    # Add text and voice to globals but keep kokoro instance
    synth_globals = Map.merge(state.globals, %{
      "text" => text,
      "voice" => voice
    })

    case Pythonx.eval(synth_code, synth_globals) do
      {result, updated_globals} ->
        elixir_result = Pythonx.decode(result)

        response = {:ok, %{
          audio_data: elixir_result["audio_data"],
          sample_rate: elixir_result["sample_rate"],
          format: elixir_result["format"]
        }}

        # Keep the updated globals (preserves kokoro instance)
        {:reply, response, %{state | globals: updated_globals}}

      {:error, reason} ->
        Logger.error("[TTSServer] Synthesis failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end
end
