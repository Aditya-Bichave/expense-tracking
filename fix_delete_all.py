import os
import re
import glob

def run():
    files = glob.glob("lib/features/*/data/repositories/*.dart")
    for f in files:
        with open(f, 'r') as fp:
            content = fp.read()
        if ".deleteAll(" in content:
            print("deleteAll found in " + f)

if __name__ == "__main__":
    run()
