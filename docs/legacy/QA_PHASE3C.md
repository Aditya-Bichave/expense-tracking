# Phase 3C: Automation & Ecosystem - Testing Guide

## 1. Recurring Expense Engine (Postgres + pg_cron)

### Prerequisites
- `pg_cron` must be enabled in Supabase Dashboard (Database -> Extensions).
- The `recurring_rules` table and functions must be deployed.

### Manual Test (SQL)

Run the following SQL in Supabase SQL Editor to verify the engine:

```sql
-- 1. Create a test recurring rule (Daily, due yesterday)
-- Replace 'USER_UUID_HERE' with a valid user ID from auth.users
INSERT INTO public.recurring_rules (
  user_id,
  group_id,
  expense_payload,
  frequency,
  timezone,
  next_due_date,
  is_active
) VALUES (
  auth.uid(),
  NULL, -- Personal expense
  '{"title": "Test Netflix Subscription", "amount": 15.99, "currency": "USD", "notes": "Automated"}',
  'DAILY',
  'Asia/Kolkata',
  now() - interval '1 hour', -- Due now
  true
);

-- 2. Verify it exists
SELECT * FROM public.recurring_rules WHERE expense_payload->>'title' = 'Test Netflix Subscription';

-- 3. Manually trigger the processor (simulate cron)
SELECT public.process_due_recurring_rules();

-- 4. Verify Expense Creation
SELECT * FROM public.expenses WHERE title = 'Test Netflix Subscription' ORDER BY created_at DESC;

-- 5. Verify Next Due Date Update
SELECT next_due_date FROM public.recurring_rules WHERE expense_payload->>'title' = 'Test Netflix Subscription';
-- Should be tomorrow relative to the previous next_due_date.

-- 6. Idempotency Test: Run it again immediately
SELECT public.process_due_recurring_rules();
-- Check expenses table again. There should still be only 1 expense created (assuming logic locks correctly and date was updated).
SELECT count(*) FROM public.expenses WHERE title = 'Test Netflix Subscription';
```

## 2. Lite Audit Log

### Test (SQL)

```sql
-- 1. Insert an expense (if you haven't already) or update one
UPDATE public.expenses
SET amount = 20.00
WHERE title = 'Test Netflix Subscription';

-- 2. Verify updated_by and updated_at
SELECT updated_by, updated_at, created_by, created_at
FROM public.expenses
WHERE title = 'Test Netflix Subscription';

-- updated_by should match your auth.uid() (or the user who ran the query)
-- updated_at should be NOW()
```

## 3. UPI Deep Link (Flutter)

### Setup
1.  Go to **Profile Settings**.
2.  Enter a valid VPA (e.g., `test@upi` or your actual VPA).
3.  Save.

### Execution
1.  The `SettlementDialog` widget is available in `lib/features/settlements/presentation/widgets/settlement_dialog.dart`.
2.  (Integration Note) Use this dialog when clicking "Settle Up" in the Group/Balances screen.
    ```dart
    showDialog(
      context: context,
      builder: (context) => SettlementDialog(
        receiverName: 'Alice',
        receiverUpiId: 'alice@okaxis',
        amount: 500,
        currency: 'INR',
        onSettled: () {
           // Call Bloc to record settlement
        },
      ),
    );
    ```
3.  **On Android/iOS Device:**
    -   Click "Pay via UPI".
    -   Verify that GPay/PhonePe/Paytm opens with the correct amount and VPA pre-filled.
    -   Return to app.
    -   Confirm "Payment Successful?" dialog appears.

### Edge Case
-   **Simulator/Emulator:** Most simulators do not have UPI apps.
-   **Expected Behavior:** Snackbar appears: "No UPI app found. VPA: [id]".
-   Click "COPY" on snackbar -> Verify VPA is copied to clipboard.
