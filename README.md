# offlineAI

A local, offline personal AI chat agent powered by [Ollama](https://ollama.com) and Node.js.
Everything runs on your own machine — no cloud accounts, no paid APIs.

---

## Windows Install

### Prerequisites
Before running the installer make sure the following are installed and available on your `PATH`:

| Dependency | Download |
|---|---|
| **Node.js LTS** | <https://nodejs.org/en/download> |
| **Ollama for Windows** | <https://ollama.com/download/windows> |

After installing them, open a new terminal window so the updated `PATH` is picked up.

### Quick start (recommended)

Double-click **`install.bat`** in the repo root, or run it from a terminal:

```bat
install.bat
```

The installer will:
1. Verify prerequisites (Node.js, npm, Ollama).
2. Run `npm install` to set up Node dependencies.
3. Pull the default Ollama model (`qwen2.5:3b`, a good fit for 8 GB RAM).
4. Set `OLLAMA_MODEL` for the current session and show you how to persist it.
5. Ask if you want to start the app immediately.

### Using PowerShell directly

```powershell
.\install.ps1
```

Or with a specific model:

```powershell
.\install.ps1 -Model qwen2.5:7b
```

### Changing the model

**Option 1 – pass it to the installer:**
```bat
install.bat qwen2.5:7b
```

**Option 2 – set an environment variable before running:**
```powershell
$env:OLLAMA_MODEL = "qwen2.5:7b"
.\install.ps1
```

**Option 3 – set it permanently (user-level):**
```powershell
[Environment]::SetEnvironmentVariable('OLLAMA_MODEL', 'qwen2.5:7b', 'User')
```

Recommended models by available RAM / VRAM:

| RAM / VRAM | Suggested model |
|---|---|
| 8 GB RAM (CPU only) | `qwen2.5:3b` *(default)* |
| 16 GB RAM (CPU only) | `llama3.1:8b` |
| 8 GB VRAM | `qwen2.5:7b` |
| 12 GB+ VRAM | `qwen2.5:14b` |

### Starting the app later

If you skipped the auto-start during installation, run from the repo root:

```bat
npm start
```

Then open your browser at `http://localhost:3000`.

---

## License

This project is open-source. See [LICENSE](LICENSE) for details.
