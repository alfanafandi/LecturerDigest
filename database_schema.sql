-- 1. Courses Table
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  name VARCHAR(255) NOT NULL,
  schedule VARCHAR(255),
  color_hex VARCHAR(7),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Lectures Table
CREATE TABLE IF NOT EXISTS lectures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  lecture_date DATE NOT NULL,
  duration_minutes INTEGER,
  status VARCHAR(50) DEFAULT 'Recorded',
  raw_transcript TEXT,
  audio_url TEXT,
  share_code VARCHAR(10) UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Summaries Table
CREATE TABLE IF NOT EXISTS summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE UNIQUE,
  core_essence TEXT,
  key_takeaways JSONB,
  exam_tips TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Flashcards Table
CREATE TABLE IF NOT EXISTS flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
  front_concept TEXT NOT NULL,
  back_detail TEXT NOT NULL,
  status VARCHAR(50) DEFAULT 'Learning',
  next_review_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  review_interval INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Quizzes Table
CREATE TABLE IF NOT EXISTS quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

 -- Buat tabel untuk menyimpan hasil kuis
create table if not exists quiz_attempts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) default auth.uid(),
  lecture_id uuid references lectures(id) on delete cascade,
  score int not null,
  total_questions int not null,
  detailed_answers jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);


-- 6. Chat Messages Table (History)
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL, -- 'user' or 'bot'
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS for all tables
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE lectures ENABLE ROW LEVEL SECURITY;
ALTER TABLE summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only manage their own data
CREATE POLICY "Users can manage their own courses" ON courses FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own lectures" ON lectures FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own summaries" ON summaries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own flashcards" ON flashcards FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own quizzes" ON quizzes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own attempts" ON quiz_attempts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own chat messages" ON chat_messages FOR ALL USING (auth.uid() = user_id);

-- Sharing Policies (Allows users to view shared content by others)
CREATE POLICY "Allow read access to lectures by share_code" ON lectures FOR SELECT USING (share_code IS NOT NULL);
CREATE POLICY "Allow read access to summaries by shared lecture" ON summaries FOR SELECT USING (lecture_id IN (SELECT id FROM lectures WHERE share_code IS NOT NULL));
CREATE POLICY "Allow read access to flashcards by shared lecture" ON flashcards FOR SELECT USING (lecture_id IN (SELECT id FROM lectures WHERE share_code IS NOT NULL));
CREATE POLICY "Allow read access to quizzes by shared lecture" ON quizzes FOR SELECT USING (lecture_id IN (SELECT id FROM lectures WHERE share_code IS NOT NULL));
CREATE POLICY "Allow read access to courses name for shared lectures" ON courses FOR SELECT USING (id IN (SELECT course_id FROM lectures WHERE share_code IS NOT NULL));

-- Indices for performance
create index idx_lectures_course_id on lectures(course_id);
create index idx_summaries_lecture_id on summaries(lecture_id);
create index idx_flashcards_lecture_id on flashcards(lecture_id);
create index idx_quizzes_lecture_id on quizzes(lecture_id);
create index idx_chat_messages_lecture_id on chat_messages(lecture_id);
create index idx_quiz_attempts_lecture_id on quiz_attempts(lecture_id);


-- 7. Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  preferences JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
