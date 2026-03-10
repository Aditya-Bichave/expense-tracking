import re
import subprocess

out = subprocess.run(['flutter', 'test', '--machine'], capture_output=True, text=True)
# The above command produces JSON output for each test event. We can parse it.
# Actually, running full flutter test might take 2 mins. I will just run it.
