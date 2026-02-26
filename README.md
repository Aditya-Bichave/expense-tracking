# Expense Tracker

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22%2B-46D1FD.svg?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-2ea44f" alt="Platforms" />
</p>

A modern, cross-platform Flutter application for managing personal finances. Record income and expenses, create budgets, and visualize how you spend your money with beautiful charts and reports.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
  - [Automated Setup](#automated-setup)
  - [Manual Setup](#manual-setup)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Features

- 💼 **Accounts & Transactions** – Add multiple accounts and record detailed income or expense entries.
- 📈 **Budgets & Categories** – Organize spending with customizable categories and monthly budgets.
- 📊 **Analytics Dashboard** – Interactive charts and summaries reveal spending patterns.
- 🔁 **Recurring Transactions** – Schedule automatic income or expense items.
- 🎯 **Goals & Reports** – Set savings goals and export CSV reports.
- 🌐 **Cross‑platform** – Runs on Android, iOS, Web, Windows, macOS, and Linux.

## Tech Stack

- **Flutter** & **Dart** for a single codebase across platforms
- **Hive** for local data storage
- **Flutter Bloc** for predictable state management
- **build_runner** with **json_serializable** for code generation
- A collection of community packages for charts, animations, and authentication (see [pubspec.yaml](pubspec.yaml))

## Getting Started

### Automated Setup

On Linux, the provided script bootstraps the Flutter and Android SDKs along with project dependencies:

```bash
./setup.sh
```

### Manual Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Aditya-Bichave/expense-tracking.git
   cd expense-tracking
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Generate code** (Hive adapters & JSON serialization)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. **Run the application**
   ```bash
   flutter run
   ```
5. **Run tests**
   ```bash
   flutter test
   ```

## Usage

Once running, create accounts, log expenses and income, and explore the analytics dashboard to understand your spending habits. Use recurring transactions for subscriptions and schedule reminders for upcoming bills.

## Contributing

Contributions, issues, and feature requests are welcome!
Please read [AGENTS.md](AGENTS.md) and the [docs/](docs/) folder for architectural guidelines and coding standards before submitting a PR.

## License

This project is licensed under the [MIT License](LICENSE).
