import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For potential IconData

enum AssetType { bank, cash, crypto, investment, other }

class AssetAccount extends Equatable {
  final String id;
  final String name;
  final AssetType type;
  final double initialBalance;
  final double currentBalance; // Calculated, not stored directly in DB model
  final IconData? iconData; // Optional: For UI representation

  const AssetAccount({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    required this.currentBalance,
    this.iconData,
  });

  // Helper for display
  String get typeName {
    switch (type) {
      case AssetType.bank:
        return 'Bank';
      case AssetType.cash:
        return 'Cash';
      case AssetType.crypto:
        return 'Crypto';
      case AssetType.investment:
        return 'Investment';
      case AssetType.other:
        return 'Other';
    }
  }

  @override
  List<Object?> get props =>
      [id, name, type, initialBalance, currentBalance, iconData];
}
