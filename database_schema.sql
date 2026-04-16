-- 1. Courses Table
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  schedule VARCHAR(255),
  color_hex VARCHAR(7),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Lectures Table
CREATE TABLE IF NOT EXISTS lectures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  lecture_date DATE NOT NULL,
  duration_minutes INTEGER,
  status VARCHAR(50) DEFAULT 'Recorded',
  raw_transcript TEXT,
  audio_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Summaries Table
CREATE TABLE IF NOT EXISTS summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE UNIQUE,
  core_essence TEXT,
  key_takeaways JSONB,
  exam_tips TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Flashcards Table
CREATE TABLE IF NOT EXISTS flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
  front_concept TEXT NOT NULL,
  back_detail TEXT NOT NULL,
  status VARCHAR(50) DEFAULT 'Learning',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Quizzes Table
CREATE TABLE IF NOT EXISTS quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

 -- Buat tabel untuk menyimpan hasil kuis
create table quiz_attempts (
  id uuid default gen_random_uuid() primary key,
  lecture_id uuid references lectures(id) on delete cascade,
  score int not null,
  total_questions int not null,
  detailed_answers jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

create index idx_quiz_attempts_lecture_id on quiz_attempts(lecture_id);


