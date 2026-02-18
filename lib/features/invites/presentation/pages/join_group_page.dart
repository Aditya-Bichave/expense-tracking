import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/invites/domain/usecases/accept_invite_usecase.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinGroupPage extends StatefulWidget {
  final String token;
  const JoinGroupPage({super.key, required this.token});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _joinGroup();
  }

  Future<void> _joinGroup() async {
    final usecase = sl<AcceptInviteUseCase>();
    final result = await usecase(AcceptInviteParams(widget.token));

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _loading = false;
            _error = failure.message;
          });
        },
        (_) {
          // Success, go to groups list
          context.go('/groups');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to join group: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/groups'),
                    child: const Text('Go to Groups'),
                  ),
                ],
              ),
      ),
    );
  }
}
