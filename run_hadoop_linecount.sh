set -euo pipefail

SRC_DIR="${SRC_DIR:-.}"

STREAMING_JAR="/usr/lib/hadoop/hadoop-streaming.jar"
if [ ! -f "$STREAMING_JAR" ]; then
  echo "[ERROR] Streaming JAR not found at: $STREAMING_JAR" >&2
  exit 1
fi
echo "[INFO] Using streaming jar: $STREAMING_JAR"
echo "[INFO] Source dir: $SRC_DIR"

# Build input list from SRC_DIR; exclude mapper/reducer themselves
mapfile -t FILES < <(find "$SRC_DIR" -maxdepth 1 -type f -name '*.py' \
  ! -name 'mapper.py' ! -name 'reducer.py' | sort)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "[ERROR] No input .py files found in $SRC_DIR (besides mapper/reducer)." >&2
  exit 2
fi
echo "[INFO] Will process:"
printf '  - %s\n' "${FILES[@]}"


hadoop fs -rm -r /tmp/input /tmp/output || true
hadoop fs -mkdir -p /tmp/input
hadoop fs -put -f "${FILES[@]}" /tmp/input/

# Run streaming (mapper detects filename from env)
hadoop jar "$STREAMING_JAR" \
  -files mapper.py,reducer.py \
  -mapper "python3 mapper.py" \
  -reducer "python3 reducer.py" \
  -input "/tmp/input/*.py" \
  -output /tmp/output

# Collect results
hadoop fs -cat /tmp/output/* > /tmp/results.txt
echo "[INFO] Wrote /tmp/results.txt"

cp /tmp/results.txt "$PWD/linecount.txt" || true
echo "[INFO] Also copied to $PWD/linecount.txt"

# Optional: persist to GCS
gsutil cp /tmp/results.txt gs://hadoop-jobs-bucket-165fb971/results.txt || true
