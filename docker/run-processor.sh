#!/bin/bash
set -euo pipefail

export SEISCOMP_ROOT="${SEISCOMP_ROOT:-/home/sysop/seiscomp}"
export PATH="$SEISCOMP_ROOT/bin:$PATH"

mkdir -p "$SEISCOMP_ROOT/var/run" "$SEISCOMP_ROOT/var/log"

module="${MODULE:?MODULE is required}"
seedlink="${SEEDLINK_HOST:-seedlink}"
scmaster="${SCMASTER_HOST:-scmaster}"
db_host="${DB_HOST:-mariadb}"
db_user="${DB_USER:-sysop}"
db_password="${DB_PASSWORD:-sysop}"
db_name="${DB_NAME:-seiscomp}"

echo "waiting for ${scmaster}:18180..."
ok=0
for _ in $(seq 1 60); do
  if python3 -c "import socket; socket.create_connection(('${scmaster}',18180),2).close()" 2>/dev/null; then
    ok=1
    break
  fi
  sleep 2
done
if [ "$ok" != "1" ]; then
  echo "${scmaster}:18180 not reachable" >&2
  exit 1
fi

python3 - "$SEISCOMP_ROOT" "$seedlink" "$scmaster" "$db_host" "$db_user" "$db_password" "$db_name" "$module" <<'ENDPY'
import os, pathlib, sys
root, seedlink, scmaster, db_host, db_user, db_password, db_name, module = sys.argv[1:]
g = pathlib.Path(root) / "etc" / "global.cfg"
text = g.read_text() if g.exists() else ""
host = os.environ.get("HOSTNAME", "task")
keys = {
    "recordstream": f"slink://{seedlink}:18000",
    "connection.server": f"{scmaster}/production",
    "connection.clientName": f"{module}-{host}",
    "database": f"mysql://{db_user}:{db_password}@{db_host}/{db_name}",
}
seen = set()
out = []
for line in text.splitlines():
    raw = line.strip()
    if not raw or raw.startswith("#") or "=" not in line:
        out.append(line)
        continue
    key = line.split("=", 1)[0].strip()
    if key in keys:
        out.append(f"{key} = {keys[key]}")
        seen.add(key)
    else:
        out.append(line)
for key, val in keys.items():
    if key not in seen:
        out.append(f"{key} = {val}")
g.parent.mkdir(parents=True, exist_ok=True)
g.write_text("\n".join(out) + "\n")
ENDPY

seiscomp enable "$module" >/dev/null || true
# Do not run `seiscomp update-config` here. trunk.py always connects to
# localhost:18180 and starts a local scmaster; that fails in a processor
# task and never writes bindings. scmaster runs update-config trunk.
echo "starting $module scmaster=${scmaster} seedlink=${seedlink}"
exec seiscomp exec "$module" --console 1
