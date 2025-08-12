import re
import sys

# List of files from the grep output
files = [
    'lib/core/theme/app_theme.dart',
    'lib/core/widgets/app_card.dart',
    'lib/core/widgets/placeholder_screen.dart',
    'lib/core/widgets/transaction_list_item.dart',
    'lib/features/accounts/presentation/pages/account_list_page.dart',
    'lib/features/accounts/presentation/pages/accounts_tab_page.dart',
    'lib/features/budgets/presentation/pages/budget_detail_page.dart',
    'lib/features/budgets/presentation/pages/budgets_sub_tab.dart',
    'lib/features/budgets/presentation/widgets/budget_card.dart',
    'lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart',
    'lib/features/categories/presentation/pages/add_edit_category_screen.dart',
    'lib/features/categories/presentation/pages/categories_sub_tab.dart',
    'lib/features/categories/presentation/widgets/category_appearance_form_section.dart',
    'lib/features/categories/presentation/widgets/category_list_item_widget.dart',
    'lib/features/categories/presentation/widgets/category_picker_dialog.dart',
    'lib/features/categories/presentation/widgets/category_selection_widget.dart',
    'lib/features/categories/presentation/widgets/icon_picker_dialog.dart',
    'lib/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart',
    'lib/features/expenses/presentation/widgets/expense_card.dart',
    'lib/features/goals/presentation/pages/goal_detail_page.dart',
    'lib/features/goals/presentation/pages/goals_sub_tab.dart',
    'lib/features/goals/presentation/widgets/goal_card.dart',
    'lib/features/income/presentation/widgets/income_card.dart',
    'lib/features/recurring_transactions/presentation/pages/add_edit_recurring_rule_page.dart',
    'lib/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart',
    'lib/features/reports/presentation/widgets/charts/chart_utils.dart',
    'lib/features/reports/presentation/widgets/charts/goal_contribution_chart.dart',
    'lib/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart',
    'lib/features/reports/presentation/widgets/charts/spending_bar_chart.dart',
    'lib/features/reports/presentation/widgets/charts/spending_pie_chart.dart',
    'lib/features/reports/presentation/widgets/charts/time_series_line_chart.dart',
    'lib/features/settings/presentation/pages/settings_page.dart',
    'lib/features/transactions/presentation/pages/add_edit_transaction_page.dart',
    'lib/features/transactions/presentation/pages/transaction_list_page.dart',
    'lib/features/transactions/presentation/widgets/transaction_calendar_view.dart',
    'lib/features/transactions/presentation/widgets/transaction_form.dart',
    'lib/features/transactions/presentation/widgets/transaction_list_item.dart',
    'lib/features/transactions/presentation/widgets/transaction_list_view.dart',
]

def replace_with_opacity(file_path):
    try:
        with open(file_path, 'r') as f:
            content = f.read()

        # This regex is designed to be safer and not match things like `withOpacity(0.2);` in a comment
        # It looks for a variable or method call before `.withOpacity`
        pattern = r'(\.withOpacity\(([^)]+)\))'

        def repl(match):
            # The full match is group 1, e.g., ".withOpacity(0.15)"
            # The inner value is group 2, e.g., "0.15"
            opacity_val_str = match.group(2)
            try:
                # Handle simple numeric values
                float(opacity_val_str)
                return f'.withAlpha((255 * {opacity_val_str}).round())'
            except ValueError:
                # Handle cases where the opacity is a variable, e.g., `withOpacity(my_opacity_var)`
                # Or a more complex expression
                return f'.withAlpha((255 * {opacity_val_str}).round())'


        new_content = re.sub(pattern, repl, content)

        if new_content != content:
            print(f"Replacing withOpacity in {file_path}")
            with open(file_path, 'w') as f:
                f.write(new_content)
        else:
            print(f"No changes needed for {file_path}")


    except FileNotFoundError:
        print(f"Error: File not found at {file_path}", file=sys.stderr)
    except Exception as e:
        print(f"An error occurred with {file_path}: {e}", file=sys.stderr)


if __name__ == "__main__":
    for file in files:
        replace_with_opacity(file)

print("Script finished.")
