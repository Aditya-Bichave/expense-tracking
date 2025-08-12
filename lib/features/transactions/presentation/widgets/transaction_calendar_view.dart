// lib/features/transactions/presentation/widgets/transaction_calendar_view.dart
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart'; // Updated path
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionCalendarView extends StatelessWidget {
  final TransactionListState state;
  final SettingsState settings;
  final CalendarFormat calendarFormat;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<TransactionEntity> selectedDayTransactions;
  final List<TransactionEntity> currentTransactionsForCalendar;
  final Function(DateTime) getEventsForDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final Function(BuildContext, TransactionEntity) navigateToDetailOrEdit;

  const TransactionCalendarView({
    super.key,
    required this.state,
    required this.settings,
    required this.calendarFormat,
    required this.focusedDay,
    required this.selectedDay,
    required this.selectedDayTransactions,
    required this.currentTransactionsForCalendar,
    required this.getEventsForDay,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.navigateToDetailOrEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == ListStatus.loading &&
        currentTransactionsForCalendar.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ListStatus.error &&
        currentTransactionsForCalendar.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                  "Error loading data for calendar: ${state.errorMessage}",
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center)));
    }

    return Column(
      children: [
        TableCalendar<TransactionEntity>(
          firstDay: DateTime.utc(2010, 1, 1),
          lastDay: DateTime.utc(2040, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.twoWeeks: '2 Weeks',
            CalendarFormat.week: 'Week',
          },
          eventLoader: (day) => getEventsForDay(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((255 * 0.3).round()),
                shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary, shape: BoxShape.circle),
            markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary, shape: BoxShape.circle),
            outsideDaysVisible: false,
            markersMaxCount: 1,
            markerSize: 5.0,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            weekendTextStyle:
                TextStyle(color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round())),
            selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
            todayTextStyle: TextStyle(color: theme.colorScheme.primary),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!,
            formatButtonTextStyle:
                TextStyle(color: theme.colorScheme.primary, fontSize: 12),
            formatButtonDecoration: BoxDecoration(
              border:
                  Border.all(color: theme.colorScheme.primary.withAlpha((255 * 0.5).round())),
              borderRadius: BorderRadius.circular(12.0),
            ),
            leftChevronIcon:
                Icon(Icons.chevron_left, color: theme.colorScheme.primary),
            rightChevronIcon:
                Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ),
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _buildSelectedDayTransactionList(context, settings),
        ),
      ],
    );
  }

  Widget _buildSelectedDayTransactionList(
      BuildContext context, SettingsState settings) {
    final theme = Theme.of(context);
    if (selectedDayTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
              "No transactions on ${DateFormatter.formatDate(selectedDay ?? focusedDay)}.",
              style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return ListView.builder(
      key: ValueKey(selectedDay),
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
      itemCount: selectedDayTransactions.length,
      itemBuilder: (ctx, index) {
        final transaction = selectedDayTransactions[index];
        return TransactionListItem(
          transaction: transaction,
          onTap: () => navigateToDetailOrEdit(context, transaction),
          currencySymbol: settings.currencySymbol,
        )
            .animate()
            .fadeIn(delay: (50 * index).ms, duration: 300.ms)
            .slideX(begin: 0.2, curve: Curves.easeOutCubic);
      },
    ).animate().fadeIn(duration: 200.ms);
  }
}
