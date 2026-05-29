# mcp-runner-claude

Tiny generator that scaffolds an npx-based MCP server **wrapper** so the API
token lives in a sibling `.env` (chmod 600) instead of inside Claude Code or
Claude Desktop config files.

## Why

Claude Code's `~/.claude.json` and Claude Desktop's `claude_desktop_config.json`
both let you declare MCP servers with inline `env:` blocks:

```json
"my-server": {
  "command": "npx",
  "args": ["@vendor/mcp-server"],
  "env": { "API_TOKEN": "sk_live_..." }
}
```

Two problems:

1. The token sits in plaintext inside a config file that's easy to leak
   (dotfile sync, screenshare, accidental git add).
2. Claude Code supports `${VAR}` expansion against your shell env; Claude
   Desktop does not. So you end up with two different setups.

The wrapper pattern fixes both: one launcher script per server, secrets in a
local `.env` it sources, and the Claude configs only reference the script
path. Same setup works for Code, Desktop, Cursor, anything that launches a
command.

## Install

No install. Clone and run:

```sh
git clone https://github.com/urecio/mcp-runner-claude.git
cd mcp-runner-claude
./generate.sh
```

## Usage

The script asks for:

- **npm package** — the MCP server package, e.g. `@vendor/mcp-server`. Add
  a version suffix to pin: `@vendor/mcp-server@1.2.3` (also `@latest`, ranges
  like `@^1.0.0`, etc — anything `npx` accepts).
- **server name** — used as the key in `mcpServers` and the directory name.
  Defaults to the package with `@` stripped and `/` replaced by `-`.
- **env vars** — one per prompt, blank line to finish. Supply as many as the
  server needs (single token, token + base URL, region + account ID + key,
  etc).
- **target directory** — defaults to `~/.local/share/mcp-servers/<name>/`.

It writes:

```
<dir>/
  run.sh    # chmod +x, sources ./.env then execs npx -y <package>
  .env      # chmod 600, keys present with empty values
```

Fill in the values in `.env`, then add the printed snippet to your Claude
configs:

```json
"<name>": {
  "command": "/abs/path/to/<dir>/run.sh"
}
```

Reconnect (`/mcp` in Claude Code, quit + reopen Claude Desktop) and you're
done.

## Gotchas

- The generated `run.sh` calls `npx` via `$PATH`, so it picks up whatever
  Node your shell is using (nvm friendly). Make sure Claude Desktop inherits
  a PATH that finds `npx` — on macOS it usually does.
- If the upstream server expects extra env vars beyond what you listed, just
  add them to `.env` manually; the wrapper sources the whole file.
- The wrapper deliberately does not source `~/.claude.env` or any other
  global env file. Per-server isolation keeps the blast radius small.

## License

MIT.
