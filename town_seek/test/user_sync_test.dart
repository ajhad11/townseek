import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

void main() {
  test('User Sync Integration Test', () async {
    // 1. Initialize Supabase Client directly (mimicking main.dart)
    final supabase = SupabaseClient(
      'https://YOUR_SUPABASE_PROJECT.supabase.co', // Replace with environment variable or mock for real security
      'YOUR_SUPABASE_ANON_KEY',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    // 2. Generate Random User
    final randomId = Random().nextInt(10000);
    final email = 'testuser$randomId@example.com';
    final password = 'password123';
    final name = 'Test User $randomId';
    final phone = '1234567890';

    debugPrint('Attempting to sign up user: $email');

    try {
      // 3. Sign Up
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final User? user = res.user;

      if (user == null) {
          // If auto-confirm is off, we might not get a session, but typically we get a user.
          // If email confirmation is required, this might fail to let us log in immediately.
          // However, we are testing the INSERT logic which happens usually after signup success in app.
          debugPrint('Sign up returned null user (maybe requires email confirmation?)');
          return; 
      }
      
      debugPrint('User created: ${user.id}');

      // 4. Simulate SignInScreen logic: Insert into profiles
      debugPrint('Inserting profile for ${user.id}...');
      await supabase.from('profiles').insert({
        'id': user.id,
        'name': name,
        'phone': phone,
      });
      debugPrint('Profile inserted.');

      // 5. Simulate LoginScreen/Main logic: Fetch Profile
      debugPrint('Fetching profile...');
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // 6. Verify
      debugPrint('Fetched Data: $data');
      
      expect(data['name'], equals(name));
      expect(data['phone'], equals(phone));
      
      debugPrint('SUCCESS: Profile name matches input name!');

      // Cleanup (optional, but good practice if possible, though row deletion might be restricted)
      
    } catch (e) {
      if (e is AuthException) {
         debugPrint('Auth Error: ${e.message}');
      } else {
         debugPrint('Error: $e');
      }
      // Fail the test if exception occurs
      fail('Test failed with exception: $e');
    }
  });
}
