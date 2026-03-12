import 'dart:io';

import 'package:collection/collection.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupPage extends StatefulWidget {
  final String? groupId;
  final GroupEntity? initialGroup;

  const CreateGroupPage({super.key, this.groupId, this.initialGroup});

  bool get isEditing => groupId != null || initialGroup != null;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  GroupType _selectedType = GroupType.trip;
  String _selectedCurrency = 'USD';
  File? _selectedPhoto;
  bool _didPrefill = false;

  GroupEntity? _resolveInitialGroup(BuildContext context) {
    if (widget.initialGroup != null) {
      return widget.initialGroup;
    }

    final groupId = widget.groupId;
    if (groupId == null) {
      return null;
    }

    final state = context.read<GroupsBloc>().state;
    if (state is! GroupsLoaded) {
      return null;
    }

    return state.groups.firstWhereOrNull((group) => group.id == groupId);
  }

  void _prefillForm(BuildContext context) {
    if (_didPrefill) {
      return;
    }

    final initialGroup = _resolveInitialGroup(context);
    if (widget.isEditing && initialGroup == null) {
      return;
    }

    if (initialGroup != null) {
      _nameController.text = initialGroup.name;
      _selectedType = initialGroup.type;
      _selectedCurrency = initialGroup.currency;
    } else {
      final settingsState = context.read<SettingsBloc>().state;
      final countryCode = settingsState.selectedCountryCode;
      _selectedCurrency = AppCountries.getCurrencyCodeForCountry(countryCode);
    }

    _didPrefill = true;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPhoto = File(pickedFile.path);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _prefillForm(context);

    final initialGroup = _resolveInitialGroup(context);
    if (widget.isEditing && initialGroup == null) {
      final groupsState = context.watch<GroupsBloc>().state;
      if (groupsState is GroupsLoading || groupsState is GroupsInitial) {
        return AppScaffold(
          appBar: AppNavBar(title: 'Edit Group'),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      return AppScaffold(
        appBar: AppNavBar(title: 'Edit Group'),
        body: const Center(
          child: Text('Unable to load this group for editing.'),
        ),
      );
    }

    final kit = context.kit;

    return BlocProvider(
      create: (_) => sl<CreateGroupBloc>(),
      child: BlocListener<CreateGroupBloc, CreateGroupState>(
        listener: (context, state) {
          if (state is CreateGroupSuccess) {
            context.pop(state.group);
          } else if (state is CreateGroupFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: AppScaffold(
          appBar: AppNavBar(
            title: widget.isEditing ? 'Edit Group' : 'Create New Group',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: kit.spacing.allMd,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        key: const ValueKey('button_groupForm_pickPhoto'),
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: kit.colors.bg,
                          backgroundImage: _selectedPhoto != null
                              ? FileImage(_selectedPhoto!)
                              : (initialGroup?.photoUrl != null
                                        ? NetworkImage(initialGroup!.photoUrl!)
                                        : null)
                                    as ImageProvider<Object>?,
                          child:
                              _selectedPhoto == null &&
                                  initialGroup?.photoUrl == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  color: kit.colors.textSecondary,
                                )
                              : null,
                        ),
                      ),
                    ),
                    kit.spacing.gapLg,
                    AppTextField(
                      key: const ValueKey('field_groupForm_name'),
                      controller: _nameController,
                      label: 'Group Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    kit.spacing.gapLg,
                    AppDropdownFormField<GroupType>(
                      key: const ValueKey('field_groupForm_type'),
                      value: _selectedType,
                      labelText: 'Group Type',
                      items: GroupType.values.map((type) {
                        return DropdownMenuItem<GroupType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_getIconForType(type)),
                              kit.spacing.gapSm,
                              Text(type.value.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    kit.spacing.gapLg,
                    AppDropdownFormField<String>(
                      key: const ValueKey('field_groupForm_currency'),
                      value: _selectedCurrency,
                      labelText: 'Currency',
                      items: AppCountries.availableCountries.map((country) {
                        return DropdownMenuItem<String>(
                          value: country.currencyCode,
                          child: Text(
                            '${country.currencyCode} (${country.currencySymbol})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedCurrency = value;
                        });
                      },
                    ),
                    kit.spacing.gapXl,
                    BlocBuilder<CreateGroupBloc, CreateGroupState>(
                      builder: (context, state) {
                        return AppButton(
                          key: const ValueKey('button_groupForm_submit'),
                          isFullWidth: true,
                          isLoading: state is CreateGroupLoading,
                          onPressed: state is CreateGroupLoading
                              ? null
                              : () => _submit(context, initialGroup),
                          label: widget.isEditing
                              ? 'Save Changes'
                              : 'Create Group',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context, GroupEntity? initialGroup) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a group.'),
        ),
      );
      return;
    }

    context.read<CreateGroupBloc>().add(
      CreateGroupSubmitted(
        name: _nameController.text.trim(),
        type: _selectedType,
        currency: _selectedCurrency,
        userId: authState.user.id,
        groupId: initialGroup?.id,
        createdBy: initialGroup?.createdBy,
        createdAt: initialGroup?.createdAt,
        existingPhotoUrl: initialGroup?.photoUrl,
        isArchived: initialGroup?.isArchived ?? false,
        photoFile: _selectedPhoto,
      ),
    );
  }

  IconData _getIconForType(GroupType type) {
    switch (type) {
      case GroupType.trip:
        return Icons.flight;
      case GroupType.couple:
        return Icons.favorite;
      case GroupType.home:
        return Icons.home;
      case GroupType.custom:
        return Icons.layers;
    }
  }
}
