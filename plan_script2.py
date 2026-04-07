import sys

def main():
    print("""
The user wants to increase total project coverage by 10 percentage points.
Since the `flutter test --coverage` failed with a timeout when doing the whole project,
we can define a coverage budget.
We know there are ~62000 code lines. A 10% increase means writing tests for ~6000 lines. Wait!
In the first message: "interpret +10% as +10 percentage points of total executable project coverage".
If the project has ~30,000 executable lines, 10% is 3,000 lines.
Let's see if we can generate coverage quickly by modifying `run_tests_ci.sh` to run parallel tests or ignoring some.
Actually, if the coverage was around 32% (from the example), 10% is large.

Let's do a single run of `flutter test --coverage --concurrency 16` and see if we can get a `lcov.info`.
If it times out, we can run it directory by directory.
""")
if __name__ == "__main__":
    main()
