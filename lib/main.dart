import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'models/transaction.dart';
import 'services/database_service.dart';

const MethodChannel _platformChannel = MethodChannel(
  'sms_parser_basically/device_settings',
);
const EventChannel _liveSmsChannel = EventChannel(
  'sms_parser_basically/live_sms',
);
const String _rupeeSymbol = '\u20B9';
const List<String> _monthLabels = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

final RegExp _incomeKeywordPattern = RegExp(
  r'(credited|received|payout|added)',
  caseSensitive: false,
);
final RegExp _expenseKeywordPattern = RegExp(
  r'(debited|sent|transferred)',
  caseSensitive: false,
);
final RegExp _amountPattern = RegExp(
  '(?:$_rupeeSymbol|Rs\\.?|INR)\\s?([\\d,]+(?:\\.\\d{1,2})?)',
  caseSensitive: false,
);

enum TransactionType { income, expense }

typedef SmsType = AndroidSMSType;
typedef SmsMessage = AndroidSMSMessage;

final class SmsReader {
  SmsReader._();

  static Future<bool> requestPermissions() async {
    final bool alreadyGranted = await AndroidSMSReader.requestPermissions();
    if (alreadyGranted) {
      return true;
    }

    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _platformChannel.invokeMethod<bool>(
            'requestSmsPermissions',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<List<SmsMessage>> fetchMessages({
    required SmsType type,
    int start = 0,
    int count = 50,
  }) {
    return AndroidSMSReader.fetchMessages(
      type: type,
      start: start,
      count: count,
    );
  }

  static Stream<SmsMessage> observeIncomingMessages() {
    return _liveSmsChannel.receiveBroadcastStream().map((dynamic event) {
      return SmsMessage.fromJson(Map<String, dynamic>.from(event as Map));
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GigIncomeApp());
}

class GigIncomeApp extends StatelessWidget {
  const GigIncomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gig Income SMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const IncomeSmsPage(),
    );
  }
}

class IncomeSmsPage extends StatefulWidget {
  const IncomeSmsPage({super.key});

import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/local_auth_service.dart';
import 'widgets/auth_gate.dart';


void main() {
  runApp(const MyApp());
}


class _IncomeSmsPageState extends State<IncomeSmsPage> {
  final bool _isAndroid = Platform.isAndroid;
  final List<IncomeSmsEntry> _messages = <IncomeSmsEntry>[];

  StreamSubscription<SmsMessage>? _incomingSubscription;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasPermission = false;
  bool _isMiuiDevice = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Initialize database
    try {
      await DatabaseService.database;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Database initialization failed: $e';
      });
      return;
    }

    if (!_isAndroid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'This app supports Android SMS only.';
      });
      return;
    }

    final bool isMiui = await _isMiuiPhone();
    final bool granted = await SmsReader.requestPermissions();
    if (!mounted) {
      return;
    }

    setState(() {
      _isMiuiDevice = isMiui;
      _hasPermission = granted;
      _isLoading = false;
      _errorMessage = granted
          ? null
          : 'SMS permission was denied. Allow SMS access to read inbox messages and listen for live payouts.';
    });

    if (!granted) {
      return;
    }

    await _refreshInbox(showLoader: false);
    _startIncomingObserver();
  }

  Future<bool> _isMiuiPhone() async {
    try {
      return await _platformChannel.invokeMethod<bool>('isMiuiDevice') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _retryPermissionRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bool granted = await SmsReader.requestPermissions();
    if (!mounted) {
      return;
    }

    setState(() {
      _hasPermission = granted;
      _isLoading = false;
      _errorMessage = granted
          ? null
          : 'SMS permission was denied. Allow SMS access to read inbox messages and listen for live payouts.';
    });

    if (!granted) {
      return;
    }

    await _refreshInbox(showLoader: false);
    _startIncomingObserver();
  }

  Future<void> _refreshInbox({bool showLoader = true}) async {
    if (!_hasPermission) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      if (showLoader) {
        _isLoading = true;
      }
    });

    try {
      final List<SmsMessage> inboxMessages = await SmsReader.fetchMessages(
        type: SmsType.inbox,
        start: 0,
        count: 50,
      );

      final List<IncomeSmsEntry> fetchedEntries = inboxMessages
          .map((SmsMessage message) => _mapMessage(message, isLive: false))
          .whereType<IncomeSmsEntry>()
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _mergeFetchedEntries(fetchedEntries);
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Failed to load inbox messages: $error';
      });
    }
  }

  void _mergeFetchedEntries(List<IncomeSmsEntry> fetchedEntries) {
    final Map<String, IncomeSmsEntry> mergedEntries =
        <String, IncomeSmsEntry>{};

    for (final IncomeSmsEntry entry in fetchedEntries) {
      mergedEntries[_entryKey(entry)] = entry;
    }

    for (final IncomeSmsEntry existing in _messages) {
      final String key = _entryKey(existing);
      final IncomeSmsEntry? current = mergedEntries[key];
      if (current == null || existing.isLive) {
        mergedEntries[key] = existing;
      }
    }

    _messages
      ..clear()
      ..addAll(
        mergedEntries.values.toList()..sort(
          (IncomeSmsEntry a, IncomeSmsEntry b) => b.date.compareTo(a.date),
        ),
      );
  }

  void _startIncomingObserver() {
    _incomingSubscription?.cancel();
    _incomingSubscription = SmsReader.observeIncomingMessages().listen(
      (SmsMessage message) {
        final IncomeSmsEntry? entry = _mapMessage(message, isLive: true);
        if (entry == null || !mounted) {
          return;
        }

        setState(() {
          _upsertEntry(entry);
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage = 'Live SMS listening failed: $error';
        });
      },
    );
  }

  void _upsertEntry(IncomeSmsEntry entry) {
    final String key = _entryKey(entry);
    final int existingIndex = _messages.indexWhere(
      (IncomeSmsEntry item) => _entryKey(item) == key,
    );

    if (existingIndex >= 0) {
      _messages[existingIndex] = entry;
    } else {
      _messages.insert(0, entry);
    }

    _messages.sort(
      (IncomeSmsEntry a, IncomeSmsEntry b) => b.date.compareTo(a.date),
    );
  }

  String _entryKey(IncomeSmsEntry entry) {
    return '${entry.address}|${entry.body}|${entry.date.millisecondsSinceEpoch}';
  }

  IncomeSmsEntry? _mapMessage(SmsMessage message, {required bool isLive}) {
    final String body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    TransactionType? transactionType;
    if (_incomeKeywordPattern.hasMatch(body)) {
      transactionType = TransactionType.income;
    } else if (_expenseKeywordPattern.hasMatch(body)) {
      transactionType = TransactionType.expense;
    }

    if (transactionType == null) {
      return null;
    }

    final Match? amountMatch = _amountPattern.firstMatch(body);
    if (amountMatch == null) {
      return null;
    }

    final DateTime sentAt = DateTime.fromMillisecondsSinceEpoch(message.date);
    final String amountStr = '$_rupeeSymbol${amountMatch.group(1)!}';
    final String senderStr = message.address.trim().isEmpty
        ? 'Unknown sender'
        : message.address;

    final IncomeSmsEntry entry = IncomeSmsEntry(
      amount: amountStr,
      address: senderStr,
      body: body,
      date: sentAt,
      isLive: isLive,
      transactionType: transactionType,
    );

    // Save to database
    _saveTransactionToDatabase(
      amountStr,
      senderStr,
      body,
      transactionType.name,
      sentAt,
    );

    return entry;
  }

  Future<void> _saveTransactionToDatabase(
    String amount,
    String sender,
    String messageBody,
    String transactionType,
    DateTime date,
  ) async {
    try {
      final transaction = Transaction(
        amount: amount,
        sender: sender,
        messageBody: messageBody,
        transactionType: transactionType,
        date: date,
      );
      await DatabaseService.insertTransaction(transaction);
    } catch (e) {
      // Silently handle duplicate transactions
    }
  }

  String _formatDate(IncomeSmsEntry entry) {
    if (entry.isLive) {
      return 'just now';
    }

    final DateTime date = entry.date;
    return '${date.day} ${_monthLabels[date.month - 1]}';
  }

  Future<void> _openBackgroundSettings() async {
    try {
      final bool opened =
          await _platformChannel.invokeMethod<bool>('openBackgroundSettings') ??
          false;
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Opened MIUI settings. Enable Autostart and remove battery restrictions for this app.'
                : 'Could not open MIUI settings automatically. Open App info and allow background activity manually.',
          ),
        ),
      );
    } on MissingPluginException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Background settings are only available on Android devices.',
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open settings: ${error.message}')),
      );
    }
  }

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalAuthService>(
          create: (_) => LocalAuthService(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<LocalAuthService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GigTax',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const AuthGate(),
      ),
    );
  }
}