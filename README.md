# Chat - AI Voice Chat with 3D Avatars

A real-time voice chat application featuring 3D animated avatars powered by AI and high-quality text-to-speech synthesis.

## Features

### 🎭 3D Animated Avatars
- Interactive 3D avatars (Julia & David) using TalkingHead library
- Real-time lip sync synchronized with speech
- Smooth animations and natural facial expressions
- Avatar voice customization with 50+ Kokoro TTS voices

### 🗣️ Voice Chat
- **Voice Input**: Browser-based speech recognition with 1-second auto-submit
- **Text Input**: Traditional text chat with Enter-to-submit
- **AI Responses**: Streaming AI chat powered by Anthropic Claude
- **Voice Output**: High-quality Kokoro TTS with optimized server-side synthesis

### 🎨 User Interface
- Clean, modern Teams-style chat interface
- Dark mode support
- Real-time message streaming
- Voice settings with American/British English options
- Conversation history with auto-scrolling

### 🔐 Authentication
- Simple human verification (3-second timer + checkbox)
- Session management
- Auto-redirect to chat when authenticated

## Technology Stack

- **Backend**: Elixir + Phoenix Framework + LiveView
- **Frontend**: JavaScript + Three.js + TalkingHead
- **AI**: Anthropic Claude API
- **TTS**: Kokoro TTS (ONNX) with PythonX integration
- **Voice**: Browser Web Speech API
- **Database**: PostgreSQL
- **Deployment**: nginx reverse proxy with SSL

## Quick Start

### Prerequisites
- Elixir 1.14+
- PostgreSQL
- Node.js 18+
- Python 3.x (for Kokoro TTS)

### Installation

1. Install dependencies:
```bash
mix setup
```

2. Install Python TTS dependencies:
```bash
pip install kokoro-onnx soundfile
```

3. Start Phoenix server:
```bash
mix phx.server
```

4. Visit [localhost:4000](http://localhost:4000)

## Configuration

### Anthropic API Key
Set your API key in `config/runtime.exs`:
```elixir
config :chat, anthropic_api_key: System.get_env("ANTHROPIC_API_KEY")
```

### Kokoro TTS
The Kokoro TTS model is pre-loaded at startup in a GenServer for optimal performance. Models are located in `priv/models/`.

### Available Voices
- **American English**: af_bella, af_nova, af_sarah, am_adam, am_fenrir, etc.
- **British English**: bf_alice, bf_emma, bm_george, bm_lewis, etc.
- See `CLAUDE.md` for full voice list

## Production Deployment

### SSL Certificates
SSL certificates are stored in `priv/certs/`. The nginx reverse proxy configuration references these certificates.

**Important:** nginx must be run with `sudo` to bind to privileged ports (80 and 443):

```bash
sudo nginx
```

To stop nginx:
```bash
sudo nginx -s stop
```

To reload nginx configuration:
```bash
sudo nginx -s reload
```

### DNS Configuration
Ensure both A (IPv4) and AAAA (IPv6) records are configured for your domain.

## Architecture Highlights

### Persistent TTS Server
- `Chat.TTSServer` GenServer keeps Kokoro model loaded in memory
- Dramatic latency reduction compared to per-request initialization
- Handles concurrent synthesis requests efficiently

### LiveView Real-time Updates
- Server-sent events for streaming AI responses
- Client-side hooks for avatar control and voice input
- Optimized DOM updates with `phx-update="ignore"` for Three.js canvas

### Voice Pipeline
```
Speech Recognition → LiveView → Claude API → Kokoro TTS → Avatar Playback
```

## Project Structure

```
lib/
  chat/
    tts.ex              # TTS interface
    tts_server.ex       # Persistent Kokoro GenServer
    conversations.ex    # Chat logic & system prompts
  chat_web/
    live/chat_live/     # Main chat interface
    controllers/
      tts_controller.ex # TTS API endpoint
assets/
  js/
    app.js             # Main JS with hooks
    avatar3.js         # 3D avatar integration
priv/
  models/            # Kokoro TTS models
  static/avatars/    # Avatar GLB files
```

## Learn More

- Phoenix Framework: https://www.phoenixframework.org/
- TalkingHead: https://github.com/met4citizen/TalkingHead
- Kokoro TTS: https://huggingface.co/hexgrad/Kokoro-82M
- Anthropic Claude: https://www.anthropic.com/
