import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to Supabase PostgreSQL...');
  
  // Connection string from user
  final connectionString = 'postgresql://postgres:[HMJ3qR1y4gY8dGRz]@db.edelvyeiknyyxhfctnra.supabase.co:5432/postgres';
  
  // Notice: The password in the string provided by user had brackets: [HMJ3qR1y4gY8dGRz]
  // In a standard URL, brackets are sometimes added by UI to denote placeholder or literally included.
  // Assuming the brackets aren't part of the password. If it fails, we will try with brackets.
  // From typical Supabase "Reset password" it has no brackets, but let's try with brackets just in case.
  String pwd = "[HMJ3qR1y4gY8dGRz]";
  
  final connection = await Connection.open(
    Endpoint(
      host: 'db.edelvyeiknyyxhfctnra.supabase.co',
      database: 'postgres',
      username: 'postgres',
      password: pwd,
      port: 5432,
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

    print('Migrations completed successfully!');
  } catch (e) {
    print('Error during migration: $e');
  } finally {
    await connection.close();
  }
}
