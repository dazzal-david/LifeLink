-- Enable Row Level Security (RLS)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Admin Users Table (Must Be Created First)
CREATE TABLE admin_users (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Blood Donors Table
CREATE TABLE blood_donors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  blood_type TEXT NOT NULL,
  location TEXT NOT NULL,
  availability BOOLEAN DEFAULT true,
  last_donation_date TIMESTAMPTZ,
  contact TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Organ Donors Table
CREATE TABLE organ_donors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  organs TEXT[] NOT NULL,
  medical_history TEXT,
  location TEXT NOT NULL,
  consent BOOLEAN DEFAULT false,
  contact TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hospitals Table
CREATE TABLE hospitals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT NOT NULL,
  services TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ✅ Auto-update updated_at field on row update
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to tables
CREATE TRIGGER update_blood_donors_timestamp
BEFORE UPDATE ON blood_donors
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_organ_donors_timestamp
BEFORE UPDATE ON organ_donors
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_hospitals_timestamp
BEFORE UPDATE ON hospitals
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- ✅ Enable RLS (Row Level Security)
ALTER TABLE blood_donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE organ_donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;

-- ✅ Blood Donors Policies
CREATE POLICY "Authenticated users can view blood donors" ON blood_donors
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create their own blood donor profile" ON blood_donors
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own blood donor profile" ON blood_donors
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own blood donor profile" ON blood_donors
  FOR DELETE USING (auth.uid() = user_id);

-- ✅ Organ Donors Policies
CREATE POLICY "Authenticated users can view organ donors" ON organ_donors
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create their own organ donor profile" ON organ_donors
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own organ donor profile" ON organ_donors
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own organ donor profile" ON organ_donors
  FOR DELETE USING (auth.uid() = user_id);

-- ✅ Hospitals Policies
CREATE POLICY "Public read access for hospitals" ON hospitals
  FOR SELECT USING (true);

-- ✅ Only allow admins to modify hospital data
CREATE POLICY "Only admins can modify hospital data" ON hospitals
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));
