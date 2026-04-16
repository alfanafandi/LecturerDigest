import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('--- Database Purge Utility ---');
  
  // Read .env manually
  Map<String, String> env = {};
  try {
    final lines = File('.env').readAsLinesSync();
    for (var line in lines) {
      if (line.contains('=') && !line.startsWith('#')) {
        final parts = line.split('=');
        env[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }
  } catch (e) {
    print('Error reading .env: $e');
    return;
  }
  
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseKey == null) {
    print('Error: Credentials not found in .env');
    return;
  }

  final headers = {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
  };

  print('Purging data in sequence...');

  // Sequence is important due to foreign keys: Flashcards -> Summaries -> Lectures
  final tables = ['flashcards', 'summaries', 'lectures', 'courses'];

  for (var table in tables) {
    print('Deleting all records from $table...');
    final url = Uri.parse('$supabaseUrl/rest/v1/$table?id=not.is.null'); // Select all
    final response = await http.delete(url, headers: headers);
    
    if (response.statusCode == 204 || response.statusCode == 200) {
      print('Success: $table cleared.');
    } else {
      print('Error clearing $table: ${response.body}');
    }
  }

  print('\nDatabase is now clean! 🧼');
}
