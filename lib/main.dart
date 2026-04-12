import 'dart:async';
import 'dart:io';

import 'package:android_sms_reader/android_sms_reader.dart';
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

  @override
  State<IncomeSmsPage> createState() => _IncomeSmsPageState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_messages.length} income ${_messages.length == 1 ? 'message' : 'messages'} found',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _hasPermission && !_isRefreshing
                ? () => _refreshInbox(showLoader: false)
                : null,
            tooltip: 'Refresh inbox',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && !_hasPermission) {
      return _PermissionDeniedView(
        message: _errorMessage!,
        onRetry: _retryPermissionRequest,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StatusCard(
          hasPermission: _hasPermission,
          messageCount: _messages.length,
          errorMessage: _errorMessage,
        ),
        if (_isMiuiDevice) ...<Widget>[
          const SizedBox(height: 12),
          _MiuiNoticeCard(onOpenSettings: _openBackgroundSettings),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyMatchesView()
              : ListView.separated(
                  itemCount: _messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final IncomeSmsEntry entry = _messages[index];
                    return _IncomeMessageTile(
                      entry: entry,
                      trailingLabel: _formatDate(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class IncomeSmsEntry {
  const IncomeSmsEntry({
    required this.amount,
    required this.address,
    required this.body,
    required this.date,
    required this.isLive,
    required this.transactionType,
  });

  final String amount;
  final String address;
  final String body;
  final DateTime date;
  final bool isLive;
  final TransactionType transactionType;
}

class _IncomeMessageTile extends StatelessWidget {
  const _IncomeMessageTile({required this.entry, required this.trailingLabel});

  final IncomeSmsEntry entry;
  final String trailingLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.currency_rupee_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          entry.amount,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(entry.address, style: theme.textTheme.bodyMedium),
        ),
        trailing: Text(trailingLabel, style: theme.textTheme.labelLarge),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.hasPermission,
    required this.messageCount,
    required this.errorMessage,
  });

  final bool hasPermission;
  final int messageCount;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            hasPermission ? Icons.sms_rounded : Icons.sms_failed_rounded,
            color: hasPermission ? colors.primary : colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage ??
                  'Scanning the last 50 inbox messages and watching live incoming SMS for income alerts.',
            ),
          ),
          const SizedBox(width: 12),
          Chip(label: Text('$messageCount matched')),
        ],
      ),
    );
  }
}

class _MiuiNoticeCard extends StatelessWidget {
  const _MiuiNoticeCard({required this.onOpenSettings});

  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'MIUI device detected',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'For Xiaomi, Redmi, and POCO phones, enable Autostart and set battery usage to Unrestricted so live SMS updates remain reliable.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open MIUI settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'SMS permission required',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Request permission again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMatchesView extends StatelessWidget {
  const _EmptyMatchesView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.payments_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No income SMS matched yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Messages must contain "credited", "received", "payout", or "added" and also include a $_rupeeSymbol amount.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
