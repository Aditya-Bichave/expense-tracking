import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/stitch/group_invitation_card.dart';

class GroupInvitationPage extends StatefulWidget {
  final String? token;

  const GroupInvitationPage({super.key, this.token});

  @override
  State<GroupInvitationPage> createState() => _GroupInvitationPageState();
}

class _GroupInvitationPageState extends State<GroupInvitationPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return BlocConsumer<DeepLinkBloc, DeepLinkState>(
      listener: (context, state) {
        if (state is DeepLinkSuccess) {
          final groupName = state.groupName ?? 'group';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joined $groupName')),
          );
          context.go('${RouteNames.groups}/${state.groupId}');
        } else if (state is DeepLinkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.go(RouteNames.dashboard);
        }
      },
      builder: (context, state) {
        if (state is DeepLinkProcessing) {
          return const AppScaffold(
            appBar: null,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLoadingIndicator(),
                  SizedBox(height: 16),
                  Text('Joining group...'),
                ],
              ),
            ),
          );
        }

        return AppScaffold(
          appBar: null,
          body: Center(
            child: widget.token != null
                ? GroupInvitationCard(
                    token: widget.token!,
                  )
                : Text('Invalid invite link.', style: kit.typography.body),
          ),
        );
      },
    );
  }
}
