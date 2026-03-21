import re

def run():
    with open('lib/features/expenses/data/repositories/expense_repository_impl.dart', 'r') as f:
        content = f.read()

    # Are there loops around delete?
    print(re.findall(r'delete.*', content))

if __name__ == "__main__":
    run()
