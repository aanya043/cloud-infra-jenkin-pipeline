set -euo pipefail

STREAMING_JAR="/usr/lib/hadoop/hadoop-streaming.jar"
if [ ! -f "$STREAMING_JAR" ]; then
  echo "[ERROR] Streaming JAR not found at: $STREAMING_JAR" >&2
  exit 1
fi
echo "[INFO] Using streaming jar: $STREAMING_JAR"

files=$(ls *.py | grep -v -E '^(mapper|reducer)\.py$' || true)
if [ -z "$files" ]; then
  echo "[ERROR] No input .py files found (besides mapper/reducer)." >&2
  exit 2
fi
echo "[INFO] Will process: $files"
hadoop fs -rm -r /tmp/input /tmp/output || true
hadoop fs -mkdir -p /tmp/input
hadoop fs -put -f $files /tmp/input/

hadoop jar "$STREAMING_JAR" \
  -files mapper.py,reducer.py \
  -mapper "python3 mapper.py" \
  -reducer "python3 reducer.py" \
  -input "/tmp/input/*.py" \
  -output /tmp/output

hadoop fs -cat /tmp/output/* > /tmp/results.txt
echo "[INFO] Wrote /tmp/results.txt"

cp /tmp/results.txt "$PWD/linecount.txt" || true
echo "[INFO] Also copied to $PWD/linecount.txt"

gsutil cp /tmp/results.txt gs://hadoop-jobs-bucket-165fb971/results.txt
