# The OG Chatbot

A lightweight, fully **offline** AI chatbot that runs entirely on your local machine using [Ollama](https://ollama.com) and Node.js — no internet connection required, no data leaves your device.

## Features

- 💬 Chat interface served from a minimal Node.js HTTP server
- 🔒 100% offline — all inference happens locally via Ollama
- 🪟 One-click Windows launcher (`start.bat`) that auto-installs Node.js and Ollama if missing
- 🤖 Configurable model (defaults to `llama3.2:3b`)
- 📜 Maintains full conversation history within the session

## Requirements

- **Windows** (the `.bat` launchers are Windows-only; `server.js` itself runs on any OS with Node.js)
- [Node.js](https://nodejs.org/) v18 or later
- [Ollama](https://ollama.com/download) with at least one model pulled (default: `llama3.2:3b`)

## Quick Start (Windows)

1. **Double-click `start.bat`** — it will:
   - Install Node.js if not already present
   - Install Ollama if not already present
   - Start the Ollama server
   - Launch the chat server and open the UI in your browser at `http://127.0.0.1:3000`

That's it. No manual setup needed.

## Manual Setup

```bash
# 1. Pull the default model (or any model you prefer)
ollama pull llama3.2:3b

# 2. Start the Ollama server (if not already running)
ollama serve

# 3. In a separate terminal, start the chat server
node server.js

# 4. Open your browser at http://127.0.0.1:3000
```

## Configuration

Open `server.js` and edit the constants near the top:

| Constant | Default | Description |
|---|---|---|
| `PORT` | `3000` | Port the chat UI is served on |
| `OLLAMA_PORT` | `11434` | Port Ollama listens on |
| `MODEL` | `"llama3.2:3b"` | Ollama model to use (e.g. `"llama3:8b"`, `"mistral"`) |
| `SYSTEM_PROMPT` | *(see file)* | Personality / instructions for the assistant |

## Project Structure

```
og-chatbot/
├── index.html          # Chat UI (single-page, no build step)
├── server.js           # Node.js HTTP server + Ollama proxy
├── start.bat           # One-click Windows launcher
├── install_node.bat    # Helper: silently installs Node.js
├── install_ollama.bat  # Helper: silently installs Ollama
└── README.md
```

## License

This project is licensed under the [MIT License](LICENSE).
