#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Naming Escalation Guard
#
# Overrides (break glass):
#   ALLOW_FORBIDDEN_DIRS=1 git commit
#   ALLOW_DATA_DUMPS=1 git commit
#   ALLOW_SECRETS=1 git commit
# ============================================================

# -----------------------------
# Configuration
# -----------------------------
MAX_FILES=40
MAX_TOP_LEVEL_DIRS=5

FORBIDDEN_DIRS=(
  "node_modules"
  "dist"
  "build"
  "coverage"
  ".next"
  ".cache"
  "__pycache__"
)

VENDORED_DIRS=(
  "vendor"
  "third_party"
  "deps"
)

SOURCE_DIRS=(
  "src"
  "app"
  "lib"
)

GENERATED_PATTERNS=(
  '\.min\.js$'
  '\.min\.css$'
  '\.map$'
)

DATA_EXTENSIONS=(
  "json"
  "csv"
  "tsv"
  "ndjson"
  "parquet"
  "xml"
)

MAX_DATA_FILES=5
MAX_DATA_TOTAL_SIZE_KB=1024

SECRET_FILES=(
  ".env"
  ".env.local"
  "id_rsa"
  "id_ed25519"
)

SECRET_PATTERNS=(
  '\.pem$'
  '\.key$'
)

# -----------------------------
# Overrides
# -----------------------------
[ "${ALLOW_FORBIDDEN_DIRS:-}" = "1" ] && {
  echo "⚠️  Naming Guard override: forbidden directories allowed"
  exit 0
}

ALLOW_DATA_DUMPS="${ALLOW_DATA_DUMPS:-0}"
ALLOW_SECRETS="${ALLOW_SECRETS:-0}"

# -----------------------------
# Gather staged files
# -----------------------------
FILES=()
while IFS= read -r f; do FILES+=("$f"); done <<EOF
$(git diff --cached --name-only)
EOF

[ "${#FILES[@]}" -eq 0 ] && exit 0

# -----------------------------
# Summary (always printed)
# -----------------------------
echo "🔎 Commit summary:"
echo "  Files staged: ${#FILES[@]}"
echo "  Top-level dirs: $(printf '%s\n' "${FILES[@]}" | cut -d/ -f1 | sort -u | tr '\n' ' ')"
echo

# -----------------------------
# Rule 1: Forbidden directories
# -----------------------------
for dir in "${FORBIDDEN_DIRS[@]}"; do
  for f in "${FILES[@]}"; do
    case "$f" in "$dir/"*)
      echo "❌ Forbidden directory detected: '${dir}/'"
      echo "   Override: ALLOW_FORBIDDEN_DIRS=1 git commit"
      exit 1 ;;
    esac
  done
done

# -----------------------------
# Rule 2: Vendored code detection
# -----------------------------
for dir in "${VENDORED_DIRS[@]}"; do
  for f in "${FILES[@]}"; do
    case "$f" in "$dir/"*)
      echo "❌ Vendored third-party code detected: '${dir}/'"
      echo "   Third-party code should not usually be committed."
      exit 1 ;;
    esac
  done
done

# -----------------------------
# Rule 3: Too many files
# -----------------------------
[ "${#FILES[@]}" -gt "$MAX_FILES" ] && {
  echo "❌ Too many files staged (${#FILES[@]} > ${MAX_FILES})"
  exit 1
}

# -----------------------------
# Rule 4: Too many top-level dirs
# -----------------------------
TOP_LEVEL_DIR_COUNT=$(printf '%s\n' "${FILES[@]}" | cut -d/ -f1 | sort -u | wc -l)
[ "$TOP_LEVEL_DIR_COUNT" -gt "$MAX_TOP_LEVEL_DIRS" ] && {
  echo "❌ Changes span too many top-level directories (${TOP_LEVEL_DIR_COUNT} > ${MAX_TOP_LEVEL_DIRS})"
  exit 1
}

# -----------------------------
# Rule 5: Generated + source mixed
# -----------------------------
HAS_SOURCE=0
HAS_GENERATED=0

for f in "${FILES[@]}"; do
  for src in "${SOURCE_DIRS[@]}"; do
    case "$f" in "$src/"*) HAS_SOURCE=1 ;; esac
  done
  for pat in "${GENERATED_PATTERNS[@]}"; do
    echo "$f" | grep -Eq "$pat" && HAS_GENERATED=1
  done
done

[ "$HAS_SOURCE" -eq 1 ] && [ "$HAS_GENERATED" -eq 1 ] && {
  echo "❌ Source files mixed with generated artifacts"
  exit 1
}

# -----------------------------
# Rule 6: Binary flood
# -----------------------------
BINARY_COUNT=$(git diff --cached --numstat | awk '$1=="-" {c++} END {print c+0}')
[ "$BINARY_COUNT" -gt 10 ] && {
  echo "❌ Large number of binary files staged (${BINARY_COUNT})"
  exit 1
}

# -----------------------------
# Rule 7: Data dump detection
# -----------------------------
DATA_FILE_COUNT=0
DATA_TOTAL_SIZE_KB=0

for f in "${FILES[@]}"; do
  ext="${f##*.}"
  for d in "${DATA_EXTENSIONS[@]}"; do
    [ "$ext" = "$d" ] || continue
    DATA_FILE_COUNT=$((DATA_FILE_COUNT + 1))
    git cat-file -e :"$f" 2>/dev/null && {
      size=$(git cat-file -s :"$f")
      DATA_TOTAL_SIZE_KB=$((DATA_TOTAL_SIZE_KB + size / 1024))
    }
  done
done

if [ "$ALLOW_DATA_DUMPS" != "1" ] &&
   { [ "$DATA_FILE_COUNT" -gt "$MAX_DATA_FILES" ] ||
     [ "$DATA_TOTAL_SIZE_KB" -gt "$MAX_DATA_TOTAL_SIZE_KB" ]; }; then
  echo "❌ Possible data dump detected"
  echo "   Files: $DATA_FILE_COUNT | Size: ${DATA_TOTAL_SIZE_KB} KB"
  echo "   Override: ALLOW_DATA_DUMPS=1 git commit"
  exit 1
fi

# -----------------------------
# Rule 8: Secret detection
# -----------------------------
if [ "$ALLOW_SECRETS" != "1" ]; then
  for f in "${FILES[@]}"; do
    for s in "${SECRET_FILES[@]}"; do
      [ "$f" = "$s" ] && {
        echo "❌ Secret file detected: $f"
        exit 1
      }
    done
    for pat in "${SECRET_PATTERNS[@]}"; do
      echo "$f" | grep -Eq "$pat" && {
        echo "❌ Possible secret detected: $f"
        exit 1
      }
    done
  done
fi

# -----------------------------
# Rule 9: Lockfile-only warning
# -----------------------------
if printf '%s\n' "${FILES[@]}" | grep -q '^package-lock.json$' &&
   ! printf '%s\n' "${FILES[@]}" | grep -q '^package.json$'; then
  echo "⚠️  Warning: package-lock.json changed without package.json"
fi

# -----------------------------
# Commit details (informational)
# -----------------------------
echo
echo "📦 Commit details:"
echo "----------------------------------------"

# Diffstat (files changed / insertions / deletions)
git diff --cached --stat

echo
echo "Files staged:"
for f in "${FILES[@]}"; do
  echo "  - $f"
done

echo "----------------------------------------"
echo "✅ Naming Guard passed. Proceeding with commit."

exit 0
