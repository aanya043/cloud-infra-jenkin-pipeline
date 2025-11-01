import os, sys, os.path

def cur_file():
    return os.path.basename(
        os.environ.get('mapreduce_map_input_file') or
        os.environ.get('map.input.file') or
        'unknown'
    )

fn = cur_file()
for _ in sys.stdin:
    print(f"{fn}\t1")
