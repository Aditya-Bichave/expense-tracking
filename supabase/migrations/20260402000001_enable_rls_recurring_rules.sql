-- Enable RLS on public.recurring_rules and add owner-only policies

ALTER TABLE public.recurring_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can select own recurring rules" ON public.recurring_rules
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recurring rules" ON public.recurring_rules
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recurring rules" ON public.recurring_rules
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own recurring rules" ON public.recurring_rules
    FOR DELETE USING (auth.uid() = user_id);
