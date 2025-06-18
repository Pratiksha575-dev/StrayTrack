import 'package:flutter/material.dart';
import 'auth_service.dart'; // Assuming this is where AuthService is defined

class SignUpDialog extends StatelessWidget {
  const SignUpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return AlertDialog(
      title: const Text('Sign Up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String email = emailController.text.trim();
            String password = passwordController.text.trim();

            final authService = AuthService();
            await authService.signUp(context, email, password);
            Navigator.pop(context);
          },
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

class SignInDialog extends StatelessWidget {
  const SignInDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return AlertDialog(
      title: const Text('Sign In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String email = emailController.text.trim();
            String password = passwordController.text.trim();

            final authService = AuthService();
            await authService.signIn(context, email, password);
            Navigator.pop(context);
          },
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
