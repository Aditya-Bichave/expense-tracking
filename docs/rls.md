# RLS Policies

## Profiles
- **Insert**: Users can insert their own profile.
- **Select**: Users can select their own profile.
- **Update**: Users can update their own profile.

## Groups
- **Select**: Members can view groups they belong to.
- **Insert**: Users can create groups.
- **Update**: Only admins of the group can update it.

## Group Members
- **Select**: Members can view other members in the same group.
- **Insert**: Only admins can add members.
- **Delete**: Users can remove themselves (leave group).

## Invites
- **Insert**: Only admins can create invites.
- **Select**: Only admins can view invites.

## Expenses, Payers, Splits, Settlements
- **Select**: Group members can view all related records.
- **Insert/Update**: Group members can add/edit expenses and settlements.
