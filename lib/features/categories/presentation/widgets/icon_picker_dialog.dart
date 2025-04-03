import 'package:flutter/material.dart';

// Simple map of representative Material Icons for categories
// TODO: Expand this significantly, potentially load from assets/config
const Map<String, IconData> availableIcons = {
  'default_category_icon': Icons.category_outlined,
  'food': Icons.restaurant_menu,
  'groceries': Icons.shopping_cart_outlined,
  'transport': Icons.directions_bus_filled_outlined,
  'car': Icons.directions_car_filled_outlined,
  'utilities': Icons.lightbulb_outline_rounded,
  'internet': Icons.wifi,
  'phone': Icons.phone_android_outlined,
  'rent': Icons.house_outlined,
  'mortgage': Icons.home_work_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'clothing': Icons.checkroom,
  'entertainment': Icons.theaters_outlined,
  'movies': Icons.movie_creation_outlined,
  'music': Icons.music_note_outlined,
  'subscriptions': Icons.subscriptions_outlined,
  'health': Icons.health_and_safety_outlined,
  'medical': Icons.medical_services_outlined,
  'fitness': Icons.fitness_center_rounded,
  'salary': Icons.work_outline_rounded,
  'freelance': Icons.computer,
  'gift': Icons.card_giftcard_rounded,
  'investment': Icons.trending_up_rounded,
  'interest': Icons.percent_rounded,
  'question': Icons.help_outline_rounded, // For Uncategorized fallback
  // Add many more...
};

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
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = availableIcons.entries.toList();
      } else {
        _filteredIcons = availableIcons.entries.where((entry) {
          return entry.key.toLowerCase().contains(query); // Search by name key
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Select Icon'),
      contentPadding:
          const EdgeInsets.fromLTRB(16, 20, 16, 0), // Adjust padding
      content: SizedBox(
        // Constrain height
        width: double.maxFinite, // Take available width
        height: MediaQuery.of(context).size.height * 0.5, // Limit height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search icons...",
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
                        maxCrossAxisExtent: 60.0, // Adjust size of items
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                      ),
                      itemCount: _filteredIcons.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredIcons[index];
                        final isSelected = entry.key == _selectedIconName;
                        return Tooltip(
                          message: entry.key, // Show name on hover/long-press
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedIconName = entry.key);
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
                                    : theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(entry.value,
                                  color: theme.colorScheme.onSurfaceVariant),
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
          child: const Text('Select'),
          onPressed: () => Navigator.of(context)
              .pop(_selectedIconName), // Return selected name
        ),
      ],
    );
  }
}
