export interface UserBalance {
  user_id: string;
  user_name: string;
  to_user_upi: string | null;
  net_balance: number; // passed from DB as float, but we will convert internally
}

export interface SettlementInstruction {
  from_user_id: string;
  from_user_name: string;
  to_user_id: string;
  to_user_name: string;
  to_user_upi: string | null;
  amount: number;
}

export function simplifyDebts(balances: UserBalance[]): SettlementInstruction[] {
  // We use minor units (e.g. cents/paise) to prevent float drift
  interface InternalBalance {
    user_id: string;
    user_name: string;
    to_user_upi: string | null;
    balance_cents: number;
  }

  let debtors: InternalBalance[] = [];
  let creditors: InternalBalance[] = [];

  for (const b of balances) {
    // Math.round safely handles rounding the float to the nearest integer cent
    const cents = Math.round(b.net_balance * 100);

    // Ignore users who are exactly settled up (0 balance)
    if (cents < 0) {
      debtors.push({
        user_id: b.user_id,
        user_name: b.user_name,
        to_user_upi: b.to_user_upi,
        balance_cents: cents,
      });
    } else if (cents > 0) {
      creditors.push({
        user_id: b.user_id,
        user_name: b.user_name,
        to_user_upi: b.to_user_upi,
        balance_cents: cents,
      });
    }
  }

  // Sort Debtors ascending (most negative first)
  // Tie-breaker: user_id ascending
  debtors.sort((a, b) => {
    if (a.balance_cents === b.balance_cents) {
      return a.user_id.localeCompare(b.user_id);
    }
    return a.balance_cents - b.balance_cents;
  });

  // Sort Creditors descending (most positive first)
  // Tie-breaker: user_id ascending
  creditors.sort((a, b) => {
    if (a.balance_cents === b.balance_cents) {
      return a.user_id.localeCompare(b.user_id);
    }
    return b.balance_cents - a.balance_cents;
  });

  const instructions: SettlementInstruction[] = [];
  let d = 0; // debtor pointer
  let c = 0; // creditor pointer

  while (d < debtors.length && c < creditors.length) {
    const debtor = debtors[d];
    const creditor = creditors[c];

    // Math.abs on debtor because their balance is negative
    const oweAmount = Math.abs(debtor.balance_cents);
    const getAmount = creditor.balance_cents;

    // Minimum amount that can be settled between these two
    const settleAmountCents = Math.min(oweAmount, getAmount);

    if (settleAmountCents > 0) {
      instructions.push({
        from_user_id: debtor.user_id,
        from_user_name: debtor.user_name,
        to_user_id: creditor.user_id,
        to_user_name: creditor.user_name,
        to_user_upi: creditor.to_user_upi,
        // Convert back to regular decimal format
        amount: settleAmountCents / 100,
      });
    }

    // Adjust balances
    debtors[d].balance_cents += settleAmountCents;
    creditors[c].balance_cents -= settleAmountCents;

    // Move pointers if someone's balance reached 0
    if (Math.abs(debtors[d].balance_cents) === 0) d++;
    if (Math.abs(creditors[c].balance_cents) === 0) c++;
  }

  return instructions;
}
