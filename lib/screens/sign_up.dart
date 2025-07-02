import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  Future<void> _signUp() async {
    if (!mounted) return; // Ensure widget is still mounted before setState
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nickname = _nicknameController.text.trim();

      // 1. Sign up the user with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Debugging: Print values before upsert
        print('Attempting to upsert profile:');
        print('User ID: ${user.id}');
        print('Nickname: $nickname');
        print('Email: $email'); // Print the email value

        // 2. If authentication successful, attempt to insert profile data
        try {
          await _supabase.from('profiles').upsert({
            'user_id': user.id,
            'nickname': nickname,
            'email': email, // <--- Added email here to match the NOT NULL constraint
          });

          // If both auth and profile creation are successful
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign up successful! Check your email for confirmation.')),
            );
            Navigator.pop(context); // Pop back to the LoginPage
          }
        } on PostgrestException catch (e) {
          // Error during profile creation (e.g., database constraint violation)
          print('PostgrestException during profile creation: ${e.message}'); // Debug print
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile creation failed: ${e.message}')),
            );
          }
        } catch (e) {
          // Any other unexpected error during profile creation
          print('Unexpected error during profile creation: $e'); // Debug print
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An unexpected error occurred during profile creation: $e')),
            );
          }
        }
      } else {
        // This case should ideally not be reached if signUp doesn't throw an AuthException
        // but returns a null user for some other reason.
        print('Sign up response user is null, but no AuthException thrown.'); // Debug print
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up failed: User not created.')),
          );
        }
      }
    } on AuthException catch (e) {
      // Error during Supabase authentication (e.g., email already registered, weak password)
      print('AuthException during sign up: ${e.message}'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up Failed: ${e.message}')),
        );
      }
    } catch (e) {
      // Catch any other unexpected errors during the initial sign-up process
      print('Unexpected error during sign up: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      // Ensure loading state is always reset
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your thoughts deserve a safe place to grow.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40), // Space after the new text
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Sign Up'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
