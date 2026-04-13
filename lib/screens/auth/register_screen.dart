import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
	const RegisterScreen({super.key});

	@override
	State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
	final _emailCtrl = TextEditingController();
	final _passwordCtrl = TextEditingController();
	final _confirmPasswordCtrl = TextEditingController();
	final _formKey = GlobalKey<FormState>();

	@override
	void dispose() {
		_emailCtrl.dispose();
		_passwordCtrl.dispose();
		_confirmPasswordCtrl.dispose();
		super.dispose();
	}

	bool _isValidEmail(String value) {
		return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
	}

	Future<void> _onRegister() async {
		if (!_formKey.currentState!.validate()) return;

		final auth = context.read<AuthProvider>();
		final ok = await auth.register(
			_emailCtrl.text.trim(),
			_passwordCtrl.text.trim(),
		);

		if (!mounted) return;

		if (ok) {
			Navigator.pop(context);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Registration successful. Please login.')),
			);
			return;
		}

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text(auth.error ?? 'Registration failed')),
		);
	}

	@override
	Widget build(BuildContext context) {
		final auth = context.watch<AuthProvider>();

		return Scaffold(
			appBar: AppBar(title: const Text('Register')),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Form(
					key: _formKey,
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							TextFormField(
								controller: _emailCtrl,
								keyboardType: TextInputType.emailAddress,
								decoration: const InputDecoration(labelText: 'Email'),
								validator: (value) {
									final v = (value ?? '').trim();
									if (v.isEmpty) return 'Email is required';
									if (!_isValidEmail(v)) return 'Enter a valid email';
									return null;
								},
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _passwordCtrl,
								obscureText: true,
								decoration: const InputDecoration(labelText: 'Password'),
								validator: (value) {
									final v = (value ?? '').trim();
									if (v.isEmpty) return 'Password is required';
									if (v.length < 6) return 'Password must be at least 6 characters';
									return null;
								},
							),
							const SizedBox(height: 12),
							TextFormField(
								controller: _confirmPasswordCtrl,
								obscureText: true,
								decoration: const InputDecoration(labelText: 'Confirm Password'),
								validator: (value) {
									final v = (value ?? '').trim();
									if (v.isEmpty) return 'Please confirm your password';
									if (v != _passwordCtrl.text.trim()) return 'Passwords do not match';
									return null;
								},
							),
							const SizedBox(height: 20),
							ElevatedButton(
								onPressed: auth.loading ? null : _onRegister,
								child: auth.loading
										? const SizedBox(
												width: 18,
												height: 18,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Text('Register'),
							),
						],
					),
				),
			),
		);
	}
}
