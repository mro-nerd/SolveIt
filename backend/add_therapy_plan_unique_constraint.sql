-- ============================================================
-- Migration: Add unique constraint on therapy_plans (child_id)
-- ============================================================
-- Each child should have at most one active therapy plan.
-- This constraint enforces that at the DB level and also makes
-- ON CONFLICT (child_id) usable in future upsert calls.
--
-- Run this once in the Supabase SQL editor.
-- ============================================================

ALTER TABLE therapy_plans
  ADD CONSTRAINT therapy_plans_child_id_unique UNIQUE (child_id);

-- Optional: if you also want to allow multiple plans per child
-- but only one per (child, doctor) pair, use this instead:
--
-- ALTER TABLE therapy_plans
--   ADD CONSTRAINT therapy_plans_child_doctor_unique UNIQUE (child_id, doctor_id);
