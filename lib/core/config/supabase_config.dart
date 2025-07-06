// lib/core/config/supabase_config.dart
class SupabaseConfig {
  // Replace with your Supabase project URL and anon key
  static const String supabaseUrl = 'https://uzvudquiuhnotuihssqy.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6dnVkcXVpdWhub3R1aWhzc3F5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjE2NDAsImV4cCI6MjA2NjA5NzY0MH0.XpWaCEzrj6A3R_JkD8YPIXPj-xBuQY0mN6J2kXGe9EQ';

  // Storage bucket names
  static const String profileImagesBucket = 'profile-images';
  static const String userContentBucket = 'user-content';

  // Table names
  static const String usersTable = 'users';
  static const String userCreationsTable = 'user_creations';
  static const String bookmarksTable = 'bookmarks';
}
