# Database Schema

## Profiles
- user_id (UUID, PK, FK auth.users)
- phone (Text)
- display_name (Text)

## Groups
- id (UUID, PK)
- name (Text)
- created_by (UUID, FK auth.users)

## Group Members
- id (UUID, PK)
- group_id (UUID, FK groups)
- user_id (UUID, FK auth.users)
- role (Enum: admin, member, viewer)

## Invites
- id (UUID, PK)
- group_id (UUID, FK groups)
- token (Text, Unique)
- expires_at (Timestamp)

## Expenses
- id (UUID, PK)
- group_id (UUID, FK groups)
- amount (Numeric)
- title (Text)
- created_by (UUID, FK auth.users)

## Expense Payers
- expense_id (UUID, FK expenses)
- payer_user_id (UUID, FK auth.users)
- amount (Numeric)

## Expense Splits
- expense_id (UUID, FK expenses)
- user_id (UUID, FK auth.users)
- amount (Numeric)
- split_type (Enum)

## Settlements
- id (UUID, PK)
- group_id (UUID, FK groups)
- from_user_id (UUID, FK auth.users)
- to_user_id (UUID, FK auth.users)
- amount (Numeric)
