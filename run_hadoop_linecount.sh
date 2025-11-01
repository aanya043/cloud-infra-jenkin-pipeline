#!/bin/bash
set -euo pipefail

# Explicit path (you confirmed both exist; use either)
STREAMING_JAR="/usr/lib/hadoop/hadoop-streaming.jar"
# STREAMING_JAR="/usr/lib/hadoop/hadoop-streaming-3.2.4.jar"

if [ ! -f "$STREAMING_JAR" ]; then
  echo "[ERROR] Streaming JAR not found at: $STREAMING_JAR" >&2
  exit 1
fi
echo "[INFO] Using streaming jar: $STREAMING_JAR"

# Clean + stage input
hadoop fs -rm -r /tmp/input /tmp/output || true
hadoop fs -mkdir -p /tmp/input
hadoop fs -put -f *.py /tmp/input/

# Run streaming job
hadoop jar "$STREAMING_JAR" \
  -files mapper.py,reducer.py \
  -mapper "python3 mapper.py" \
  -reducer "python3 reducer.py" \
  -input /tmp/input \
  -output /tmp/output

# Collect results
hadoop fs -cat /tmp/output/* > /tmp/results.txt
echo "[INFO] Wrote /tmp/results.txt"

# Optional: make Jenkins fetch step work without changes
cp /tmp/results.txt "$PWD/linecount.txt" || true
echo "[INFO] Also copied to $PWD/linecount.txt"

# (Optional) keep your GCS upload
gsutil cp /tmp/results.txt gs://hadoop-jobs-bucket-165fb971/results.txt
