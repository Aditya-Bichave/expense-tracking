# Domain Model & Database Schema

The application uses a **Supabase (PostgreSQL)** backend as the source of truth, synchronized with a **Hive (NoSQL)** local database for offline-first capabilities.

## 1. Profiles
Represents a user in the system.
*   `user_id` (UUID, PK): References `auth.users`.
*   `phone` (Text): E.164 format.
*   `display_name` (Text): User's public name.

## 2. Groups
A collection of users sharing expenses.
*   `id` (UUID, PK): Unique identifier.
*   `name` (Text): Group name.
*   `created_by` (UUID, FK): References `auth.users`.
*   `currency` (Text): ISO 4217 code (default: USD).

## 3. Group Members
Association between Users and Groups with roles.
*   `id` (UUID, PK): Unique identifier.
*   `group_id` (UUID, FK): References `groups.id`.
*   `user_id` (UUID, FK): References `auth.users`.
*   `role` (Enum): `admin`, `member`, `viewer`.

## 4. Invites
Secure tokens for joining groups.
*   `id` (UUID, PK): Unique identifier.
*   `group_id` (UUID, FK): References `groups.id`.
*   `token` (Text, Unique): Secure random token.
*   `expires_at` (Timestamp): Expiration time (typically 24h).

## 5. Expenses
Financial transactions within a group.
*   `id` (UUID, PK): Unique identifier.
*   `group_id` (UUID, FK): References `groups.id`.
*   `amount` (Numeric): Total expense amount.
*   `title` (Text): Description.
*   `created_by` (UUID, FK): References `auth.users`.
*   `date` (Timestamp): Date of expense.

### 5.1 Expense Payers
Who paid for the expense.
*   `expense_id` (UUID, FK): References `expenses.id`.
*   `payer_user_id` (UUID, FK): References `auth.users`.
*   `amount` (Numeric): Amount paid.

### 5.2 Expense Splits
Who owes money for the expense.
*   `expense_id` (UUID, FK): References `expenses.id`.
*   `user_id` (UUID, FK): References `auth.users`.
*   `amount` (Numeric): Amount owed.
*   `split_type` (Enum): `equal`, `exact`, `percentage`.

## 6. Settlements
Repayments between users to settle debts.
*   `id` (UUID, PK): Unique identifier.
*   `group_id` (UUID, FK): References `groups.id`.
*   `from_user_id` (UUID, FK): Payer.
*   `to_user_id` (UUID, FK): Payee.
*   `amount` (Numeric): Amount settled.
