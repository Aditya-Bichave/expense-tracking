import subprocess, glob

test_files = glob.glob('test/**/*_test.dart', recursive=True)
cmd = ['flutter', 'test', '--coverage'] + test_files
subprocess.run(cmd)
