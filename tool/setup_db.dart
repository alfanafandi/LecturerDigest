import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('--- LecturerDigest Database Setup ---');
  
  // Load .env manually for a simple Dart script
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found! Please create it from .env.example');
    return;
  }

  final lines = await envFile.readAsLines();
  final Map<String, String> env = {};
  for (var line in lines) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }

  final host = env['DB_HOST'];
  final user = env['DB_USER'];
  final password = env['DB_PASSWORD'];
  final portStr = env['DB_PORT'];
  final database = env['DB_NAME'] ?? 'postgres';

  if (host == null || user == null || password == null || portStr == null) {
    print('Error: Database credentials missing in .env!');
    print('Please ensure DB_HOST, DB_USER, DB_PASSWORD, and DB_PORT are set.');
    return;
  }

  final port = int.tryParse(portStr) ?? 5432;

  print('Connecting to Supabase PostgreSQL at $host...');
  
  final connection = await Connection.open(
    Endpoint(
      host: host,
      database: database,
      username: user,
      password: password,
      port: port,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('Connected! Running migrations...');

  try {
    // 1. Courses Table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS courses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        schedule VARCHAR(255),
        color_hex VARCHAR(7),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    print('Created courses table.');

    // 2. Lectures Table
    await connection.execute('''
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
    ''');
    print('Created lectures table.');

    // 3. Summaries Table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS summaries (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE UNIQUE,
        core_essence TEXT,
        key_takeaways JSONB,
        exam_tips TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    print('Created summaries table.');

    // 4. Flashcards Table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
        front_concept TEXT NOT NULL,
        back_detail TEXT NOT NULL,
        status VARCHAR(50) DEFAULT 'Learning',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    print('Created flashcards table.');

    // 5. Quizzes Table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS quizzes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
        question TEXT NOT NULL,
        options JSONB NOT NULL,
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    print('Created quizzes table.');

    // 6. Quiz Attempts Table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS quiz_attempts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        detailed_answers JSONB DEFAULT '[]'::JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    print('Created quiz_attempts table.');

    // 7. Indexes
    await connection.execute('CREATE INDEX IF NOT EXISTS idx_quiz_attempts_lecture_id ON quiz_attempts(lecture_id);');
    print('Created indexes.');

    print('Migrations completed successfully!');
  } catch (e) {
    print('Error during migration: $e');
  } finally {
    await connection.close();
  }
}
