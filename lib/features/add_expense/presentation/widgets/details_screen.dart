import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_chip.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart'; // Added import
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DetailsScreen extends StatefulWidget {
  final Function(bool isGroup) onNext;
  final VoidCallback onBack;

  const DetailsScreen({super.key, required this.onNext, required this.onBack});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AddExpenseWizardBloc>().state;
    _descController.text = state.description;
    _notesController.text = state.notes;
  }

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BlocConsumer<AddExpenseWizardBloc, AddExpenseWizardState>(
      listener: (context, state) {
        // Update controllers if state changes externally (optional)
      },
      builder: (context, state) {
        return AppScaffold(
          appBar: AppNavBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
              color: kit.colors.textPrimary,
            ),
            title: 'Details',
            actions: [
              Padding(
                padding: kit.spacing.hSm,
                child: AppButton(
                  variant: UiVariant.ghost,
                  size: AppButtonSize.small,
                  onPressed: state.groupId == null
                      ? () => context
                          .read<AddExpenseWizardBloc>()
                          .add(const SubmitExpense())
                      : () => widget.onNext(true),
                  label: state.groupId == null ? 'SAVE' : 'NEXT',
                ),
              ),
            ],
          ),
          body: ListView(
            padding: kit.spacing.allMd,
            children: [
              // Context Selector (Pill)
              Center(
                child: GestureDetector(
                  onTap: () => _showGroupSelector(context),
                  child: AppChip(
                    icon: Icon(
                      state.groupId == null ? Icons.person : Icons.group,
                      size: 16,
                      color: kit.colors.textPrimary,
                    ),
                    label: state.selectedGroup?.name ?? 'Personal',
                    isSelected: false,
                    onSelected: () => _showGroupSelector(context),
                  ),
                ),
              ),
              kit.spacing.gapLg,

              // Description
              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'What is this for?',
                onChanged: (val) => context.read<AddExpenseWizardBloc>().add(
                      DescriptionChanged(val),
                    ),
              ),
              kit.spacing.gapLg,

              // Categories Grid
              Text(
                'Category',
                style: kit.typography.labelMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              kit.spacing.gapSm,
              SizedBox(
                height: 40, // Height for chips
                child: FutureBuilder<dynamic>(
                  future: sl<CategoryRepository>().getAllCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final result = snapshot.data;
                    return result.fold(
                      (failure) => Text(
                        'Error loading categories',
                        style: kit.typography.caption
                            .copyWith(color: kit.colors.error),
                      ),
                      (List<Category> categories) {
                        final topCategories = categories.take(10).toList();
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: topCategories.length,
                          separatorBuilder: (_, __) => kit.spacing.wSm,
                          itemBuilder: (context, index) {
                            final cat = topCategories[index];
                            final isSelected = state.categoryId == cat.id;
                            return AppChip(
                              label: cat.name,
                              isSelected: isSelected,
                              onSelected: () {
                                context
                                    .read<AddExpenseWizardBloc>()
                                    .add(CategorySelected(cat));
                                if (_descController.text.isEmpty) {
                                  _descController.text = cat.name;
                                  context
                                      .read<AddExpenseWizardBloc>()
                                      .add(DescriptionChanged(cat.name));
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              kit.spacing.gapLg,

              // Receipt & Date Row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: kit.spacing.allSm,
                      onTap: () => _showReceiptOptions(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt,
                            size: 20,
                            color: kit.colors.textSecondary,
                          ),
                          kit.spacing.wSm,
                          Flexible(
                            child: Text(
                              state.receiptLocalPath != null
                                  ? 'Receipt Attached'
                                  : 'Attach Receipt',
                              style: kit.typography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (state.isUploadingReceipt) ...[
                            kit.spacing.wSm,
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  kit.spacing.wMd,
                  Expanded(
                    child: AppCard(
                      padding: kit.spacing.allSm,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: state.expenseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          context.read<AddExpenseWizardBloc>().add(
                                DateChanged(date),
                              );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: kit.colors.textSecondary,
                          ),
                          kit.spacing.wSm,
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(state.expenseDate),
                            style: kit.typography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              kit.spacing.gapLg,

              // Notes
              AppTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                maxLines: 2,
                onChanged: (val) =>
                    context.read<AddExpenseWizardBloc>().add(NotesChanged(val)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGroupSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: 'Select Context',
        child: const _GroupSelectorContent(),
      ),
    );
  }

  void _showReceiptOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AppBottomSheet(
        title: 'Receipt Options',
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  if (parentContext.mounted) {
                    await _pickReceipt(parentContext, ImageSource.camera);
                  }
                },
              ),
              AppListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  if (parentContext.mounted) {
                    await _pickReceipt(parentContext, ImageSource.gallery);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReceipt(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      if (!context.mounted) return;
      context.read<AddExpenseWizardBloc>().add(ReceiptSelected(picked.path));
    }
  }
}

class _GroupSelectorContent extends StatelessWidget {
  const _GroupSelectorContent();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          AppListTile(
            leading: const Icon(Icons.person),
            title: const Text('Personal Expense'),
            onTap: () async {
              context.read<AddExpenseWizardBloc>().add(
                    const GroupSelected(null),
                  );
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<dynamic>(
              future: sl<GroupsRepository>().getGroups(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return snapshot.data.fold(
                  (failure) =>
                      const Center(child: Text('Error loading groups')),
                  (List<GroupEntity> groups) {
                    if (groups.isEmpty) {
                      return const Center(child: Text('No groups found'));
                    }
                    return ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return AppListTile(
                          leading: const Icon(Icons.group),
                          title: Text(group.name),
                          onTap: () async {
                            context.read<AddExpenseWizardBloc>().add(
                                  GroupSelected(group),
                                );
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
