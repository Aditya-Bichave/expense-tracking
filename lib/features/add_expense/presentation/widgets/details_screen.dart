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
    return BlocConsumer<AddExpenseWizardBloc, AddExpenseWizardState>(
      listener: (context, state) {
        // Update controllers if state changes externally (optional)
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            title: const Text('Details'),
            actions: [
              if (state.groupId == null)
                TextButton(
                  onPressed: () {
                    context.read<AddExpenseWizardBloc>().add(
                      const SubmitExpense(),
                    );
                  },
                  child: const Text('SAVE'),
                )
              else
                TextButton(
                  onPressed: () => widget.onNext(true),
                  child: const Text('NEXT'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Context Selector (Pill)
              Center(
                child: ActionChip(
                  avatar: Icon(
                    state.groupId == null ? Icons.person : Icons.group,
                  ),
                  label: Text(state.selectedGroup?.name ?? 'Personal'),
                  onPressed: () => _showGroupSelector(context),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this for?',
                ),
                onChanged: (val) => context.read<AddExpenseWizardBloc>().add(
                  DescriptionChanged(val),
                ),
              ),
              const SizedBox(height: 24),

              // Categories Grid
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100, // Fixed height for scrolling
                child: FutureBuilder<dynamic>(
                  future: sl<CategoryRepository>().getAllCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final result = snapshot.data;
                    return result.fold(
                      (failure) => const Text('Error loading categories'),
                      (List<Category> categories) {
                        // Sort by usage? Or just take top 8
                        final topCategories = categories.take(10).toList();
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: topCategories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final cat = topCategories[index];
                            final isSelected = state.categoryId == cat.id;
                            return ChoiceChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  context.read<AddExpenseWizardBloc>().add(
                                    CategorySelected(cat),
                                  );
                                  if (_descController.text.isEmpty) {
                                    _descController.text = cat.name;
                                    context.read<AddExpenseWizardBloc>().add(
                                      DescriptionChanged(cat.name),
                                    );
                                  }
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
              const SizedBox(height: 24),

              // Receipt & Date Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _showReceiptOptions(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt),
                            const SizedBox(width: 8),
                            Text(
                              state.receiptLocalPath != null
                                  ? 'Receipt Attached'
                                  : 'Attach Receipt',
                            ),
                            if (state.isUploadingReceipt) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: state.expenseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (date != null) {
                          context.read<AddExpenseWizardBloc>().add(
                            DateChanged(date),
                          );
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(state.expenseDate),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
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
      builder: (context) => _GroupSelectorSheet(),
    );
  }

  void _showReceiptOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickReceipt(parentContext, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickReceipt(parentContext, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceipt(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      context.read<AddExpenseWizardBloc>().add(ReceiptSelected(picked.path));
    }
  }
}

class _GroupSelectorSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: Column(
        children: [
          const Text(
            'Select Context',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Personal Expense'),
            onTap: () {
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return snapshot.data.fold(
                  (failure) => const Text('Error loading groups'),
                  (List<GroupEntity> groups) {
                    if (groups.isEmpty) return const Text('No groups found');
                    return ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(group.name),
                          onTap: () {
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
