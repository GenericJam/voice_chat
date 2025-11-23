defmodule Chat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Load Whisper serving before starting children
    whisper_serving = load_whisper_serving()

    children = [
      ChatWeb.Telemetry,
      Chat.Repo,
      {DNSCluster, query: Application.get_env(:chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chat.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Chat.Finch},
      # Start TTS server with pre-loaded Kokoro model
      Chat.TTSServer,
      # Start Whisper server with pre-loaded model
      {Chat.WhisperServer, whisper_serving},
      # Start a worker by calling: Chat.Worker.start_link(arg)
      # {Chat.Worker, arg},
      # Start to serve requests, typically the last entry
      ChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp load_whisper_serving do
    IO.puts("Loading Whisper model...")
    Nx.global_default_backend({EMLX.Backend, device: :gpu})

    {:ok, whisper} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "openai/whisper-tiny"})

    serving =
      Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
        defn_options: [compiler: EMLX]
      )

    IO.puts("✅ Whisper model loaded successfully")
    serving
  end
end
