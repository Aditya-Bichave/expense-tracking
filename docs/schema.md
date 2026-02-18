# Database Schema

## Tables

### profiles
- **user_id** (uuid, PK, ref: auth.users)
- **phone** (text)
- **display_name** (text)
- **created_at** (timestamptz)

### groups
- **id** (uuid, PK)
- **name** (text)
- **created_by** (uuid, ref: auth.users)
- **created_at** (timestamptz)
- **updated_at** (timestamptz)

### group_members
- **id** (uuid, PK)
- **group_id** (uuid, ref: groups)
- **user_id** (uuid, ref: auth.users)
- **role** (enum: admin, member, viewer)
- **joined_at** (timestamptz)

### invites
- **id** (uuid, PK)
- **group_id** (uuid, ref: groups)
- **created_by** (uuid, ref: auth.users)
- **token** (text, unique)
- **expires_at** (timestamptz)
- **max_uses** (int)
- **uses_count** (int)
- **created_at** (timestamptz)

### expenses
- **id** (uuid, PK)
- **group_id** (uuid, ref: groups)
- **created_by** (uuid, ref: auth.users)
- **title** (text)
- **amount** (numeric)
- **currency** (text)
- **occurred_at** (timestamptz)
- **notes** (text)
- **updated_at** (timestamptz)

### expense_payers
- **id** (uuid, PK)
- **expense_id** (uuid, ref: expenses)
- **payer_user_id** (uuid, ref: auth.users)
- **amount** (numeric)

### expense_splits
- **id** (uuid, PK)
- **expense_id** (uuid, ref: expenses)
- **user_id** (uuid, ref: auth.users)
- **amount** (numeric)
- **split_type** (enum: equal, percent, exact)
- **meta** (jsonb)

### settlements
- **id** (uuid, PK)
- **group_id** (uuid, ref: groups)
- **from_user_id** (uuid, ref: auth.users)
- **to_user_id** (uuid, ref: auth.users)
- **amount** (numeric)
- **currency** (text)
- **created_at** (timestamptz)

## Indexes
- idx_groups_created_by
- idx_group_members_group_id
- idx_group_members_user_id
- idx_invites_token
- idx_expenses_group_id
- idx_settlements_group_id
