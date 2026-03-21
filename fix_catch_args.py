import os
import re
import glob

def run():
    files = glob.glob("lib/features/*/data/repositories/*.dart")

    for path in files:
        with open(path, 'r') as f:
            content = f.read()

        # log.severe only takes 1 or 2 optional args: message, [error], [stacktrace]
        # In dart's `logging` package, severe takes 3 args: (Object? message, [Object? error, StackTrace? stackTrace])
        # Wait, the error is: "Too many positional arguments: 1 expected, but 3 found".
        # Actually `log.severe` usually takes 3 arguments but maybe `simple_logger` only takes one?
        # The pubspec says `simple_logger: ^1.10.0` or `logging: ^1.3.0`
        # Let's check `lib/core/utils/logger.dart` to see how `log` is defined.
        pass

if __name__ == "__main__":
    run()
