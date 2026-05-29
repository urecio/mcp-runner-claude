#!/bin/sh
# mcp-runner-claude: scaffold an npx-based MCP server wrapper so that the
# API token lives in a sibling .env (chmod 600), not in Claude Code or
# Claude Desktop config files.
#
# Output: <dir>/run.sh + <dir>/.env (with empty values to fill in).
# Then add the printed snippet to your Claude configs.

set -e

prompt() {
	# $1 = question, $2 = default (optional)
	if [ -n "$2" ]; then
		printf "%s [%s]: " "$1" "$2" >&2
	else
		printf "%s: " "$1" >&2
	fi
	IFS= read -r REPLY
	if [ -z "$REPLY" ] && [ -n "$2" ]; then
		REPLY="$2"
	fi
	printf "%s" "$REPLY"
}

PACKAGE=$(prompt "npm package (e.g. @vendor/mcp-server)")
if [ -z "$PACKAGE" ]; then
	echo "package required" >&2
	exit 1
fi

# derive a default name from the package: strip leading @, replace / with -
DEFAULT_NAME=$(printf "%s" "$PACKAGE" | sed 's|^@||' | tr '/' '-')
NAME=$(prompt "server name (used in config + folder)" "$DEFAULT_NAME")

echo "Env vars to inject (one per line, blank line to finish):" >&2
KEYS=""
i=1
while :; do
	K=$(prompt "  env var #$i (e.g. API_TOKEN)")
	[ -z "$K" ] && break
	# strip whitespace
	K=$(printf "%s" "$K" | tr -d ' 	')
	KEYS="$KEYS $K"
	i=$((i + 1))
done
if [ -z "$KEYS" ]; then
	echo "at least one env var required" >&2
	exit 1
fi

DEFAULT_DIR="$HOME/.local/share/mcp-servers/$NAME"
DIR=$(prompt "target directory" "$DEFAULT_DIR")

mkdir -p "$DIR"
RUN="$DIR/run.sh"
ENVFILE="$DIR/.env"

if [ -e "$RUN" ]; then
	echo "refuse to overwrite existing $RUN" >&2
	exit 1
fi

cat > "$RUN" <<EOF
#!/bin/sh
# $NAME MCP launcher.
# Sources sibling .env (chmod 600) and execs the npx-published server.
cd "\$(dirname "\$0")" || exit 1
set -a; . ./.env; set +a
exec npx -y $PACKAGE
EOF
chmod +x "$RUN"

if [ -e "$ENVFILE" ]; then
	echo "note: $ENVFILE already exists, leaving it alone" >&2
else
	: > "$ENVFILE"
	chmod 600 "$ENVFILE"
	for k in $KEYS; do
		printf "%s=\n" "$k" >> "$ENVFILE"
	done
fi

cat <<EOF

Wrote: $RUN
Wrote: $ENVFILE   (chmod 600 — fill in values before launching)

Add this under "mcpServers" in:
  - Claude Code:    ~/.claude.json
  - Claude Desktop: ~/Library/Application Support/Claude/claude_desktop_config.json

  "$NAME": {
    "command": "$RUN"
  }

Then reconnect (/mcp in Claude Code, quit + reopen Claude Desktop).
EOF
