# Supabase Integration Setup Guide

## Prerequisites

- Supabase account (sign up at https://supabase.com/)
- Flutter development environment

## Step 1: Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: "bharat-ace"
   - Database Password: (choose a strong password)
   - Region: (choose closest to your users)
5. Click "Create new project"

## Step 2: Get Project Credentials

1. In your Supabase dashboard, go to Settings > API
2. Copy the following:
   - Project URL (something like: https://xyz.supabase.co)
   - Public anon key (starts with "eyJ...")

## Step 3: Update Configuration

1. Open `lib/core/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL_HERE';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
   ```

## Step 4: Set Up Database Schema

1. In your Supabase dashboard, go to SQL Editor
2. Copy the contents from `supabase_schema.sql`
3. Paste and run the SQL commands
4. This will create:
   - `users` table for user profiles
   - `user_creations` table for uploaded content
   - `bookmarks` table for saved content
   - Storage buckets for images and videos
   - Security policies and functions

## Step 5: Configure Storage

1. Go to Storage in your Supabase dashboard
2. Verify these buckets exist:
   - `profile-images` (for user profile pictures)
   - `user-content` (for uploaded images and videos)
3. Both should be set to "Public" for easy access

## Step 6: Test the Integration

1. Run your Flutter app: `flutter run`
2. Sign up a new user
3. Try uploading profile image
4. Try uploading content in the creation section
5. Check your Supabase dashboard to see the data

## Features Implemented

### User Management

- ✅ Automatic user sync to Supabase on signup
- ✅ Profile image upload and storage
- ✅ User data persistence

### Content Management

- ✅ Image and video upload to Supabase Storage
- ✅ Automatic thumbnail generation for videos
- ✅ Real-time content streaming
- ✅ View and like counting
- ✅ Content deletion

### Storage

- ✅ Organized file structure
- ✅ Public access URLs
- ✅ Automatic file naming with timestamps
- ✅ MIME type detection

## File Structure Changes

```
lib/
├── core/
│   ├── config/
│   │   └── supabase_config.dart          # Supabase configuration
│   ├── services/
│   │   └── supabase_service.dart         # Supabase operations
│   └── providers/
│       └── supabase_providers.dart       # Riverpod providers for Supabase
└── screens/
    └── profile_screen.dart               # Updated to use Supabase
```

## Security Notes

- Row Level Security (RLS) is enabled on all tables
- Users can only access their own data
- Public read access for content discovery
- Secure storage policies prevent unauthorized access
- All sensitive operations use authenticated requests

## Troubleshooting

### Common Issues:

1. **"supabase_url not found" error**

   - Make sure you updated `supabase_config.dart` with your actual project URL

2. **Storage upload fails**

   - Check that storage buckets exist and are set to public
   - Verify storage policies are correctly applied

3. **Database connection issues**

   - Verify your anon key is correct
   - Check that your database is active (not paused)

4. **RLS Policy errors**
   - Make sure all SQL commands from `supabase_schema.sql` were executed
   - Check that policies are enabled for your tables

### Getting Help

- Check Supabase documentation: https://supabase.com/docs
- Review Supabase logs in your dashboard
- Test individual functions in the SQL editor

## Next Steps

1. **Authentication Integration**: Connect Supabase Auth with your existing Firebase Auth
2. **Real-time Features**: Add real-time collaboration features
3. **Advanced Queries**: Implement search and filtering
4. **Caching**: Add local caching for better performance
5. **Analytics**: Track user engagement and content performance

## Migration from Firebase

Since you're currently using Firebase, you can run both systems in parallel:

1. New users will be synced to Supabase
2. Existing Firebase data can be migrated gradually
3. Eventually phase out Firebase components

The current implementation allows for seamless transition without breaking existing functionality.
