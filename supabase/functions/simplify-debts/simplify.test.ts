import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { simplifyDebts, UserBalance, SettlementInstruction } from "./simplify.ts";

Deno.test("Scenario 1: The Circular Debt (A->B->C->A)", () => {
  // A pays $10 for B. B pays $10 for C. C pays $10 for A.
  // Net balances: A=0, B=0, C=0
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 0 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: 0 },
    { user_id: "C", user_name: "C", to_user_upi: null, net_balance: 0 },
  ];

  const result = simplifyDebts(balances);
  assertEquals(result.length, 0, "Circular debt should result in no instructions");
});

Deno.test("Scenario 2: The Perfect Match", () => {
  // A pays $100 for B. C pays $50 for D.
  // Net balances: A=+100, B=-100, C=+50, D=-50
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 100 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: -100 },
    { user_id: "C", user_name: "C", to_user_upi: null, net_balance: 50 },
    { user_id: "D", user_name: "D", to_user_upi: null, net_balance: -50 },
  ];

  const result = simplifyDebts(balances);
  // Sort expected outcome to match greedy algorithm logic deterministic output
  // Debtors: B (-100), D (-50)
  // Creditors: A (100), C (50)

  assertEquals(result.length, 2);
  assertEquals(result[0].from_user_id, "B");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 100);

  assertEquals(result[1].from_user_id, "D");
  assertEquals(result[1].to_user_id, "C");
  assertEquals(result[1].amount, 50);
});

Deno.test("Scenario 3: The 'One Pays For All' (The Hub)", () => {
  // A pays $30 for A, B, C ($10 each)
  // Net balances: A=+20, B=-10, C=-10
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 20 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: -10 },
    { user_id: "C", user_name: "C", to_user_upi: null, net_balance: -10 },
  ];

  const result = simplifyDebts(balances);

  // Debtors: B (-10), C (-10). User ID tie breaker: B then C
  // Creditors: A (+20)

  assertEquals(result.length, 2);
  assertEquals(result[0].from_user_id, "B");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 10);

  assertEquals(result[1].from_user_id, "C");
  assertEquals(result[1].to_user_id, "A");
  assertEquals(result[1].amount, 10);
});

Deno.test("Scenario 4: The Penny Problem Simulation", () => {
  // A pays $10.00 for A, B, C. Splits: A=$3.34, B=$3.33, C=$3.33
  // Net balances: A=+6.66, B=-3.33, C=-3.33
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 6.66 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: -3.33 },
    { user_id: "C", user_name: "C", to_user_upi: null, net_balance: -3.33 },
  ];

  const result = simplifyDebts(balances);

  // Debtors: B (-3.33), C (-3.33)
  // Creditors: A (+6.66)

  assertEquals(result.length, 2);
  assertEquals(result[0].from_user_id, "B");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 3.33);

  assertEquals(result[1].from_user_id, "C");
  assertEquals(result[1].to_user_id, "A");
  assertEquals(result[1].amount, 3.33);
});

Deno.test("Scenario 5: Exact zero balance exclusion", () => {
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 5.00 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: 0.00 }, // Ignored
    { user_id: "C", user_name: "C", to_user_upi: null, net_balance: -5.00 },
  ];

  const result = simplifyDebts(balances);

  assertEquals(result.length, 1);
  assertEquals(result[0].from_user_id, "C");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 5.00);
});

Deno.test("Scenario 6: Partial settlements already recorded", () => {
  // A pays 100 for B. B sends 40 to A manually.
  // Net balances: A = 100 - 40 = 60. B = -100 + 40 = -60.
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 60.00 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: -60.00 },
  ];

  const result = simplifyDebts(balances);

  assertEquals(result.length, 1);
  assertEquals(result[0].from_user_id, "B");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 60.00);
});

Deno.test("Scenario 7: Deterministic Output Sorting Check", () => {
  // Multiple debtors with the same balance
  const balances: UserBalance[] = [
    { user_id: "Z_debtor", user_name: "Z", to_user_upi: null, net_balance: -10 },
    { user_id: "A_debtor", user_name: "A", to_user_upi: null, net_balance: -10 },
    { user_id: "Creditor", user_name: "C", to_user_upi: null, net_balance: 20 },
  ];

  const result = simplifyDebts(balances);

  assertEquals(result.length, 2);
  // Tie breaking sorts by user_id ascending when balances match
  assertEquals(result[0].from_user_id, "A_debtor");
  assertEquals(result[1].from_user_id, "Z_debtor");
});

Deno.test("Scenario 8: Performance Sanity (Many Members)", () => {
  const balances: UserBalance[] = [];
  const N = 50; // max expected usually
  for (let i = 0; i < N - 1; i++) {
    balances.push({ user_id: `U${i}`, user_name: `U${i}`, to_user_upi: null, net_balance: -10 });
  }
  balances.push({ user_id: `UC`, user_name: `UC`, to_user_upi: null, net_balance: (N - 1) * 10 });

  const start = performance.now();
  const result = simplifyDebts(balances);
  const end = performance.now();

  assertEquals(result.length, N - 1);
  // Under 200ms
  assertEquals((end - start) < 200, true);
});

Deno.test("Scenario 9: Complex Circular and Multi-hop Debt", () => {
  // Net balances: A: +100, B: +50, C: -80, D: -70
  // Debts sum = -150, Credits sum = +150
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 100 },
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: 50 },
    { user_id: "C", user_name: "C", to_user_upi: null, net_balance: -80 },
    { user_id: "D", user_name: "D", to_user_upi: null, net_balance: -70 },
  ];

  const result = simplifyDebts(balances);

  // Debtors: C (-80), D (-70)
  // Creditors: A (+100), B (+50)

  // C (-80) pays A (+100) -> C is settled. A remaining is +20.
  // D (-70) pays A (+20) -> D remaining is -50. A is settled.
  // D (-50) pays B (+50) -> D is settled. B is settled.

  assertEquals(result.length, 3);

  assertEquals(result[0].from_user_id, "C");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 80);

  assertEquals(result[1].from_user_id, "D");
  assertEquals(result[1].to_user_id, "A");
  assertEquals(result[1].amount, 20);

  assertEquals(result[2].from_user_id, "D");
  assertEquals(result[2].to_user_id, "B");
  assertEquals(result[2].amount, 50);
});

Deno.test("Scenario 10: Float Drift Safety (Small floats rounding)", () => {
  const balances: UserBalance[] = [
    { user_id: "A", user_name: "A", to_user_upi: null, net_balance: 0.1 + 0.2 }, // Float returns 0.30000000000000004
    { user_id: "B", user_name: "B", to_user_upi: null, net_balance: -0.3 },
  ];

  const result = simplifyDebts(balances);

  assertEquals(result.length, 1);
  assertEquals(result[0].from_user_id, "B");
  assertEquals(result[0].to_user_id, "A");
  assertEquals(result[0].amount, 0.3);
});
