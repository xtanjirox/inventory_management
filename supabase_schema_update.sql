-- 1. Update the `products` table to include the new columns
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS image_path TEXT,
ADD COLUMN IF NOT EXISTS variants_json TEXT;

-- 2. Create the `activities` table for history logging
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    quantity_change INTEGER,
    note TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp BIGINT NOT NULL
);

-- 3. Enable RLS on activities
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for activities (users can only see and modify their own activities)
CREATE POLICY "Users can view their own activities" 
ON public.activities FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activities" 
ON public.activities FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activities" 
ON public.activities FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own activities" 
ON public.activities FOR DELETE 
USING (auth.uid() = user_id);

-- 5. Add an index for faster history sorting
CREATE INDEX IF NOT EXISTS idx_activities_timestamp 
ON public.activities(timestamp DESC);
