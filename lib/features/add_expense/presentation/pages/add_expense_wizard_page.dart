import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/numpad_screen.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/details_screen.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/split_screen.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AddExpenseWizardPage extends StatelessWidget {
  const AddExpenseWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<AddExpenseWizardBloc>()..add(const WizardStarted()),
      child: const AddExpenseWizardView(),
    );
  }
}

class AddExpenseWizardView extends StatefulWidget {
  const AddExpenseWizardView({super.key});

  @override
  State<AddExpenseWizardView> createState() => _AddExpenseWizardViewState();
}

class _AddExpenseWizardViewState extends State<AddExpenseWizardView> {
  final PageController _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          NumpadScreen(onNext: _nextPage),
          DetailsScreen(
            onNext: (isGroup) {
              if (isGroup) {
                _nextPage();
              } else {
                // DetailsScreen handles Submit for Personal.
              }
            },
            onBack: () {
              if (_pageController.page == 0) {
                Navigator.of(context).pop();
              } else {
                _prevPage();
              }
            },
          ),
          SplitScreen(onBack: _prevPage),
        ],
      ),
    );
  }
}
