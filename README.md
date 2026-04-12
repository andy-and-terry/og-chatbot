# og-chatbot

Local/offline chat UI powered by **Ollama** + **Node.js**. Runs on your own machine.

## Windows quick start

Run:

- `start.bat`

It will:
- refresh PATH for the current session
- start `ollama serve`
- start `node server.js`
- open `http://127.0.0.1:3000`
- optionally create a Desktop shortcut

### Run without the Desktop shortcut

CMD:
- `cd /d "<REPO_PATH>" && start.bat`

PowerShell:
- `Set-Location "<REPO_PATH>"; .\start.bat`

> The script prints your actual `<REPO_PATH>` when you run it.

## License

If a `LICENSE` file exists in this repo, it applies. Otherwise, license is currently unspecified.
