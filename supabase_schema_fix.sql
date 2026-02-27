-- Fix 1: Make 'color' nullable or provide a default in categories 
-- (since our local model doesn't have a color field)
ALTER TABLE public.categories 
ALTER COLUMN color DROP NOT NULL;

-- Note: The products insert failed because the category it references
-- wasn't inserted due to the 'color' constraint failing above.
-- Once the categories insert succeeds, the products insert will also succeed.
