import subprocess

def run_cmd(cmd):
    return subprocess.check_output(cmd, shell=True, text=True)

# Fetch issues since I can't easily parse from memory in a script, I'll just look at them.
