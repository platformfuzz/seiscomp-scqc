#!/bin/bash
set -euo pipefail

export SEISCOMP_ROOT="${SEISCOMP_ROOT:-/home/sysop/seiscomp}"
export PATH="$SEISCOMP_ROOT/bin:$PATH"

module="${MODULE:?MODULE is required}"
seedlink="${SEEDLINK_HOST:-seedlink}"
scmaster="${SCMASTER_HOST:-scmaster}"
db_host="${DB_HOST:-mariadb}"
db_user="${DB_USER:-sysop}"
db_password="${DB_PASSWORD:-sysop}"
db_name="${DB_NAME:-seiscomp}"

python3 - "$SEISCOMP_ROOT" "$seedlink" "$scmaster" "$db_host" "$db_user" "$db_password" "$db_name" <<'PY'
import pathlib, sys
root, seedlink, scmaster, db_host, db_user, db_password, db_name = sys.argv[1:]
g = pathlib.Path(root) / "etc" / "global.cfg"
text = g.read_text() if g.exists() else ""
keys = {
    "recordstream": f"slink://{seedlink}:18000",
    "connection.server": f"{scmaster}/production",
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
PY

seiscomp enable "$module" >/dev/null || true
echo "starting $module scmaster=${scmaster} seedlink=${seedlink}"
exec seiscomp exec "$module" --console 1
