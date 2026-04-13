import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../read_sms.dart';

class SmsHomeScreen extends StatelessWidget {
	const SmsHomeScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return ReadSmsScreen(
			appBarActions: [
				IconButton(
					icon: const Icon(Icons.logout),
					tooltip: 'Logout',
					onPressed: () => context.read<AuthProvider>().logout(),
				),
			],
		);
	}
}
