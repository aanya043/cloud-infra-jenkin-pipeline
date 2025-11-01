#!/bin/bash
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
