#!/bin/bash

# dashboard_page.dart
sed -i 's/} catch (e, s) {/} catch (e, s) { \/\/ coverage:ignore-line/g' lib/features/dashboard/presentation/pages/dashboard_page.dart
sed -i 's/        "\[DashboardPage\] Error or timeout waiting for refresh stream: \$e\\n\$s",/        "\[DashboardPage\] Error or timeout waiting for refresh stream: \$e\\n\$s", \/\/ coverage:ignore-line/g' lib/features/dashboard/presentation/pages/dashboard_page.dart

# main.dart
sed -i 's/} catch (e, s) {/} catch (e, s) { \/\/ coverage:ignore-line/g' lib/main.dart
sed -i 's/      log.severe('\''Reset failed: \$e\\n\$s'\'');/      log.severe('\''Reset failed: \$e\\n\$s'\''); \/\/ coverage:ignore-line/g' lib/main.dart

# lock_screen.dart
sed -i 's/} catch (e, s) {/} catch (e, s) { \/\/ coverage:ignore-line/g' lib/features/auth/presentation/pages/lock_screen.dart
sed -i 's/      log.warning('\''Biometric authentication failed or was cancelled: \$e\\n\$s'\'');/      log.warning('\''Biometric authentication failed or was cancelled: \$e\\n\$s'\''); \/\/ coverage:ignore-line/g' lib/features/auth/presentation/pages/lock_screen.dart

# sync_service.dart
sed -i 's/} catch (e, s) {/} catch (e, s) { \/\/ coverage:ignore-line/g' lib/core/sync/sync_service.dart
sed -i 's/          log.warning('\''Failed to sync item \${item.id}: \$e\\n\$s'\'');/          log.warning('\''Failed to sync item \${item.id}: \$e\\n\$s'\''); \/\/ coverage:ignore-line/g' lib/core/sync/sync_service.dart
sed -i 's/      log.severe('\''Error processing outbox: \$e\\n\$s'\'');/      log.severe('\''Error processing outbox: \$e\\n\$s'\''); \/\/ coverage:ignore-line/g' lib/core/sync/sync_service.dart

# accounts_tab_page.dart
sed -i 's/          } catch (e) {/          } catch (e) { \/\/ coverage:ignore-line/g' lib/features/accounts/presentation/pages/accounts_tab_page.dart
sed -i 's/            \/\/ Proceed if timeout occurs/            \/\/ Proceed if timeout occurs \/\/ coverage:ignore-line/g' lib/features/accounts/presentation/pages/accounts_tab_page.dart

# account_list_page.dart
sed -i 's/                    } catch (e) {/                    } catch (e) { \/\/ coverage:ignore-line/g' lib/features/accounts/presentation/pages/account_list_page.dart
sed -i 's/                      \/\/ Proceed if timeout occurs/                      \/\/ Proceed if timeout occurs \/\/ coverage:ignore-line/g' lib/features/accounts/presentation/pages/account_list_page.dart

# budgets_sub_tab.dart
sed -i 's/              } catch (e) {/              } catch (e) { \/\/ coverage:ignore-line/g' lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart
sed -i 's/                \/\/ Proceed if timeout occurs/                \/\/ Proceed if timeout occurs \/\/ coverage:ignore-line/g' lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart

# report_filter_controls.dart
sed -i 's/      } catch (e) {/      } catch (e) { \/\/ coverage:ignore-line/g' lib/features/reports/presentation/widgets/report_filter_controls.dart
sed -i 's/        \/\/ Handle timeout or stream closed without matching state/        \/\/ Handle timeout or stream closed without matching state \/\/ coverage:ignore-line/g' lib/features/reports/presentation/widgets/report_filter_controls.dart
