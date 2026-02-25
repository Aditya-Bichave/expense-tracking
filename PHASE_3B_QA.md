# Phase 3B QA Checklist

## 1. Personal Expense (Frictionless Path)
- [ ] Tap "Dashboard FAB" (Main + button).
- [ ] Verify Numpad screen opens.
- [ ] Enter Amount (e.g., 15).
- [ ] Tap Next.
- [ ] Verify Details screen opens (Description focused).
- [ ] Enter Description ("Coffee").
- [ ] Select Category ("Food") from grid.
- [ ] Verify Context is "Personal Expense" (Default).
- [ ] Tap SAVE.
- [ ] Verify Snackbar "Expense added securely." appears.
- [ ] Verify wizard closes and returns to Dashboard.
- [ ] (Dev) Verify Outbox contains 'create_expense_transaction' mutation with correct payload.

## 2. Group Expense (Split Logic)
- [ ] Tap "Dashboard FAB".
- [ ] Enter Amount (e.g., 100).
- [ ] Tap Next.
- [ ] Tap "Personal Expense" pill -> Select a Group (e.g., "Goa Trip").
- [ ] Tap NEXT (Button changes from SAVE to NEXT).
- [ ] Verify Split Screen opens.
- [ ] Verify Default: "Equal Split" selected.
- [ ] Verify Default: Current User pays 100%.
- [ ] Toggle "Percentages". Verify inputs appear.
- [ ] Enter invalid percentages (sum != 100). Verify error message.
- [ ] Enter valid percentages (50/50). Verify SAVE enabled.
- [ ] Tap SAVE.
- [ ] Verify success.

## 3. Receipt Attachment
- [ ] In Details Screen, tap "Attach Receipt".
- [ ] Select "Camera" or "Gallery".
- [ ] Pick an image.
- [ ] Verify UI shows "Attach Receipt" -> Spinner -> "Receipt Attached".
- [ ] Verify file is compressed (check logs or file size if possible).
- [ ] Verify upload to Supabase 'receipts' bucket starts.
- [ ] Save Expense.
- [ ] (Dev) Verify payload includes 'p_receipt_url'.

## 4. Offline/Failure Resilience
- [ ] Disconnect Network.
- [ ] Attach Receipt (Upload will fail or hang).
- [ ] Save Expense.
- [ ] Verify app does NOT block.
- [ ] Verify Snackbar "Expense added securely.".
- [ ] (Dev) Verify payload has 'p_receipt_url': null.
- [ ] (Dev) Verify payload has 'x_local_receipt_path': '...'.
- [ ] (Dev) Verify SyncEngine (Phase 2A) eventually handles this (out of scope for 3B but good to check).

## 5. UI/UX
- [ ] Verify "3-second rule" for personal expense.
- [ ] Verify Numpad is responsive.
- [ ] Verify Category Grid horizontal scroll.
