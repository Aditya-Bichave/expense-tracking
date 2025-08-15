// lib/features/categories/presentation/widgets/icon_picker_dialog.dart
import 'package:flutter/material.dart';

// --- Populate this map extensively! ---
Map<String, IconData> availableIcons = {
  'default_category_icon': Icons.category_outlined,
  'category': Icons.category_outlined, // Alias
  'label': Icons.label_outline, // Alias
  'question': Icons.help_outline_rounded,
  // Expenses
  'food': Icons.restaurant_menu_outlined,
  'restaurant': Icons.restaurant_outlined,
  'groceries': Icons.shopping_cart_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'clothing': Icons.checkroom_outlined,
  'transport': Icons.directions_bus_filled_outlined,
  'car': Icons.directions_car_filled_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'parking': Icons.local_parking_outlined,
  'utilities': Icons.lightbulb_outline_rounded,
  'internet': Icons.wifi_outlined,
  'phone': Icons.phone_iphone_outlined,
  'water': Icons.water_drop_outlined,
  'electricity': Icons.electrical_services_outlined,
  'rent': Icons.house_outlined,
  'mortgage': Icons.home_work_outlined,
  'housing': Icons.real_estate_agent_outlined,
  'entertainment': Icons.theaters_outlined,
  'movies': Icons.movie_creation_outlined,
  'music': Icons.music_note_outlined,
  'games': Icons.sports_esports_outlined,
  'subscriptions': Icons.subscriptions_outlined,
  'health': Icons.health_and_safety_outlined,
  'medical': Icons.medical_services_outlined,
  'pharmacy': Icons.local_pharmacy_outlined,
  'fitness': Icons.fitness_center_rounded,
  'education': Icons.school_outlined,
  'books': Icons.book_outlined,
  'personal_care': Icons.spa_outlined,
  'pets': Icons.pets_outlined,
  'travel': Icons.flight_takeoff_rounded,
  'vacation': Icons.beach_access_outlined,
  'hotel': Icons.hotel_outlined,
  // Income
  'salary': Icons.work_outline_rounded,
  'freelance': Icons.computer_outlined,
  'bonus': Icons.emoji_events_outlined,
  'gift': Icons.card_giftcard_rounded,
  'investment': Icons.trending_up_rounded,
  'interest': Icons.percent_rounded,
  'refund': Icons.replay_outlined,
  // Other General
  'bank': Icons.account_balance_outlined,
  'cash': Icons.wallet_outlined,
  'credit_card': Icons.credit_card_outlined,
  'savings': Icons.savings_outlined,
  'business': Icons.business_center_outlined,
  'childcare': Icons.child_care_outlined,
  'charity': Icons.volunteer_activism_outlined,
  'taxes': Icons.receipt_long_outlined,
  'other': Icons.more_horiz,
  // Add many more...
};
// --- End populated map ---

// Function to show the icon picker dialog
Future<String?> showIconPicker(
    BuildContext context, String currentIconName) async {
  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return IconPickerDialogContent(currentIconName: currentIconName);
    },
  );
}

class IconPickerDialogContent extends StatefulWidget {
  final String currentIconName;
  const IconPickerDialogContent({super.key, required this.currentIconName});

  @override
  State<IconPickerDialogContent> createState() =>
      _IconPickerDialogContentState();
}

class _IconPickerDialogContentState extends State<IconPickerDialogContent> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedIconName;
  List<MapEntry<String, IconData>> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _selectedIconName = widget.currentIconName;
    _filteredIcons = availableIcons.entries.toList(); // Initial list
    _searchController.addListener(_filterIcons);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterIcons);
    _searchController.dispose();
    super.dispose();
  }

  void _filterIcons() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = availableIcons.entries.toList();
      } else {
        _filteredIcons = availableIcons.entries.where((entry) {
          // Search by key (name)
          return entry.key.toLowerCase().contains(query);
        }).toList();
      }
      // Optional: Sort filtered results alphabetically by key
      _filteredIcons.sort((a, b) => a.key.compareTo(b.key));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Select Icon'),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search icons by name...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear())
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredIcons.isEmpty
                  ? const Center(child: Text("No matching icons found."))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 60.0,
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                        childAspectRatio: 1.0, // Make items square
                      ),
                      itemCount: _filteredIcons.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredIcons[index];
                        final isSelected = entry.key == _selectedIconName;
                        return Tooltip(
                          message: entry.key,
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedIconName = entry.key);
                              // Optionally pop immediately on selection:
                              // Navigator.of(context).pop(_selectedIconName);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                        .withOpacity(0.3)
                                    : theme.colorScheme
                                        .surfaceContainerHighest, // Use a background color
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(
                                  4), // Add padding around icon
                              child: Icon(entry.value,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 28), // Slightly larger icon
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(), // Return null
        ),
        TextButton(
          key: const ValueKey('button_select'),
          child: const Text('Select'),
          onPressed: () => Navigator.of(context)
              .pop(_selectedIconName), // Return selected name
        ),
      ],
    );
  }
}
