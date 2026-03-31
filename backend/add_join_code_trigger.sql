-- Create the function that generates a 6-character random join code
CREATE OR REPLACE FUNCTION generate_join_code()
RETURNS TRIGGER AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate 6 uppercase letters/numbers
        new_code := upper(substring(md5(random()::text) FROM 1 FOR 6));
        
        -- Check if code exists to prevent collisions
        SELECT EXISTS(SELECT 1 FROM public.children WHERE join_code = new_code) INTO code_exists;
        
        IF NOT code_exists THEN
            NEW.join_code := new_code;
            EXIT;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it already exists, then create it
DROP TRIGGER IF EXISTS trigger_generate_join_code ON public.children;

CREATE TRIGGER trigger_generate_join_code
    BEFORE INSERT ON public.children
    FOR EACH ROW
    WHEN (NEW.join_code IS NULL)
    EXECUTE FUNCTION generate_join_code();

-- Retroactively fix any existing children that have a null join_code
UPDATE public.children 
SET join_code = upper(substring(md5(random()::text) FROM 1 FOR 6))
WHERE join_code IS NULL;
