// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

Deno.serve(async (req) => {
  try {
    const now = new Date()
    console.log(`Processing recurring expenses for ${now.toISOString()}`)

    // Fetch active recurring expenses due for execution
    const { data: expenses, error } = await supabase
      .from('recurring_expenses')
      .select('*')
      .eq('is_active', true)
      .lte('next_run_at', now.toISOString())

    if (error) throw error

    console.log(`Found ${expenses.length} expenses due.`)

    const results = []

    for (const recurring of expenses) {
      // Create the expense
      const { data: newExpense, error: createError } = await supabase
        .from('expenses')
        .insert({
          group_id: recurring.group_id,
          created_by: recurring.created_by, // Or system user? Usually original creator.
          title: recurring.title, // Add (Recurring)?
          amount: recurring.amount,
          currency: recurring.currency,
          occurred_at: now.toISOString(), // Use execution time or scheduled time?
          notes: recurring.notes,
        })
        .select()
        .single()

      if (createError) {
        console.error(`Failed to create expense for recurring ${recurring.id}: `, createError)
        results.push({ id: recurring.id, status: 'failed', error: createError })
        continue
      }

      // Handle Payers and Splits
      // Assuming split_config = { payers: [...], splits: [...] }
      const config = recurring.split_config
      if (config && config.payers) {
         const payers = config.payers.map((p: any) => ({ ...p, expense_id: newExpense.id }))
         await supabase.from('expense_payers').insert(payers)
      }
      if (config && config.splits) {
         const splits = config.splits.map((s: any) => ({ ...s, expense_id: newExpense.id }))
         await supabase.from('expense_splits').insert(splits)
      }

      // Update next_run_at
      const nextRun = calculateNextRun(new Date(recurring.next_run_at), recurring.frequency, recurring.interval)

      await supabase
        .from('recurring_expenses')
        .update({
          last_run_at: now.toISOString(),
          next_run_at: nextRun.toISOString(),
        })
        .eq('id', recurring.id)

      results.push({ id: recurring.id, status: 'success', new_expense_id: newExpense.id })
    }

    return new Response(JSON.stringify(results), { headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(String(err), { status: 500 })
  }
})

function calculateNextRun(current: Date, frequency: string, interval: number = 1): Date {
  const next = new Date(current)
  switch (frequency) {
    case 'daily':
      next.setDate(next.getDate() + interval)
      break
    case 'weekly':
      next.setDate(next.getDate() + (7 * interval))
      break
    case 'monthly':
      next.setMonth(next.getMonth() + interval)
      break
    case 'yearly':
      next.setFullYear(next.getFullYear() + interval)
      break
  }
  return next
}
