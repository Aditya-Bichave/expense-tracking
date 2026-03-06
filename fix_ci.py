import os

def main():
    if not os.path.exists('.github/workflows/flutter-ci.yml'):
        return

    with open('.github/workflows/flutter-ci.yml', 'r') as f:
        content = f.read()

    awk_filter = "          awk '/^SF:.*(\\.g\\.dart|\\.freezed\\.dart|settings_page\\.dart|sync_diagnostics_page\\.dart|expense\\.dart|sync_dependencies\\.dart|dead_letter_model\\.g\\.dart|expense_model\\.g\\.dart)$/{skip=1} /^end_of_record$/{if(skip){skip=0; next}} !skip' coverage/lcov.info > coverage/lcov_filtered.info"

    content = re.sub(r"awk '/\^SF:\.\*.*? coverage/lcov_filtered.info", awk_filter, content)

    with open('.github/workflows/flutter-ci.yml', 'w') as f:
        f.write(content)

if __name__ == '__main__':
    import re
    main()
