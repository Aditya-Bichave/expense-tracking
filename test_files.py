import glob

def run():
    files = glob.glob("lib/features/*/data/repositories/*.dart")
    for f in files:
        with open(f, 'r') as fp:
            if "delete" in fp.read():
                print(f)

run()
