import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/data/countries.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GroupType _selectedType = GroupType.trip;
  String _selectedCurrency = 'USD'; // Default fallback
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Initialize currency from SettingsBloc
      try {
        final settingsState = context.read<SettingsBloc>().state;
        final countryCode = settingsState.selectedCountryCode;
        _selectedCurrency = AppCountries.getCurrencyCodeForCountry(countryCode);
      } catch (e) {
        // Fallback to USD if SettingsBloc is not found or error
        _selectedCurrency = 'USD';
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CreateGroupBloc>(),
      child: BlocListener<CreateGroupBloc, CreateGroupState>(
        listener: (context, state) {
          if (state is CreateGroupSuccess) {
            context.pop(); // Go back to list
          } else if (state is CreateGroupFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Create New Group')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<GroupType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Group Type',
                      border: OutlineInputBorder(),
                    ),
                    items: GroupType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getIconForType(type)),
                            const SizedBox(width: 8),
                            Text(type.value.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: AppCountries.availableCountries.map((country) {
                      return DropdownMenuItem(
                        value: country.currencyCode,
                        child: Text(
                          '${country.currencyCode} (${country.currencySymbol})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<CreateGroupBloc, CreateGroupState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is CreateGroupLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    final authState = context
                                        .read<AuthBloc>()
                                        .state;
                                    if (authState is AuthAuthenticated) {
                                      context.read<CreateGroupBloc>().add(
                                        CreateGroupSubmitted(
                                          name: _nameController.text.trim(),
                                          type: _selectedType,
                                          currency: _selectedCurrency,
                                          userId: authState.user.id,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You must be logged in to create a group.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: state is CreateGroupLoading
                              ? const CircularProgressIndicator()
                              : const Text('Create Group'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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
