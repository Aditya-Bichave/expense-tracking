for file in \
  lib/core/services/notification_service.dart \
  lib/core/services/upi_service.dart \
  lib/core/utils/color_utils.dart \
  lib/core/utils/currency_formatter.dart \
  lib/core/utils/date_formatter.dart \
  lib/features/auth/presentation/pages/e2e_bypass_page.dart \
  lib/features/groups/presentation/bloc/group_balances/group_balances_bloc.dart \
  lib/features/groups/presentation/bloc/group_balances/nudge_bloc.dart \
  lib/features/settings/domain/usecases/toggle_app_lock.dart \
  lib/features/settlements/presentation/bloc/record_settlement_bloc.dart; do
  sed -i '1s/^/import '\''package:expense_tracker\/core\/utils\/logger.dart'\'';\n/' "$file"
done
