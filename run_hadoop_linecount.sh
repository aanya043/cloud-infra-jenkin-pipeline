#!/bin/bash
set -euo pipefail

# --- Locate Hadoop Streaming JAR dynamically ---
DEFAULT_STREAMING_JAR="/usr/lib/hadoop-mapreduce/hadoop-streaming.jar"
if [ -f "$DEFAULT_STREAMING_JAR" ]; then
  STREAMING_JAR="$DEFAULT_STREAMING_JAR"
else
  STREAMING_JAR="$(hadoop classpath | tr ':' '\n' | grep -m1 'streaming.*jar' || true)"
fi

if [ -z "$STREAMING_JAR" ] || [ ! -f "$STREAMING_JAR" ]; then
  echo "[ERROR] Could not locate Hadoop Streaming JAR on this node." >&2
  exit 1
fi
echo "[INFO] Using streaming jar: $STREAMING_JAR"

hadoop fs -rm -r /tmp/input /tmp/output
hadoop fs -mkdir /tmp/input
hadoop fs -put *.py /tmp/input/
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-streaming.jar \
  -files mapper.py,reducer.py \
  -mapper mapper.py \
  -reducer reducer.py \
  -input /tmp/input \
  -output /tmp/output
hadoop fs -cat /tmp/output/* > /tmp/results.txt
gsutil cp /tmp/results.txt gs://hadoop-jobs-bucket-165fb971/results.txt
