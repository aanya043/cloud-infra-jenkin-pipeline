import sys
for line in sys.stdin:
    print(f"{sys.argv[1] if len(sys.argv)>1 else 'unknown'}\t1")