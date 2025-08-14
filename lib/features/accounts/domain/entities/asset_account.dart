import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For IconData

enum AssetType { bank, cash, crypto, investment, other }

class AssetAccount extends Equatable {
  final String id;
  final String name;
  final AssetType type;
  final double initialBalance;
  final double currentBalance; // Calculated, not stored directly in DB model
  final String colorHex;

  const AssetAccount({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    required this.currentBalance,
    required this.colorHex,
  });

  AssetAccount copyWith({
    String? id,
    String? name,
    AssetType? type,
    double? initialBalance,
    double? currentBalance,
    String? colorHex,
  }) {
    return AssetAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  // Helper for display name
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

  // Helper for getting an appropriate icon
  IconData get iconData {
    switch (type) {
      case AssetType.bank:
        return Icons.account_balance;
      case AssetType.cash:
        return Icons.wallet;
      case AssetType.crypto:
        return Icons.currency_bitcoin;
      case AssetType.investment:
        return Icons.trending_up;
      case AssetType.other:
        return Icons.credit_card; // Or Icons.help_outline
    }
  }

  @override
  List<Object?> get props =>
      [id, name, type, initialBalance, currentBalance, colorHex];
}
