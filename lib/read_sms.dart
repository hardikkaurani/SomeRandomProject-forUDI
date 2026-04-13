import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';
import 'tax-intelligence/index.dart';
import 'widgets/transaction_card.dart';
import 'widgets/tax_health_card.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/income_summary_card.dart';
import 'theme/app_spacing.dart';

// --- Model ---

class ParsedIncome {
  final double amount;
  final String source;
  final DateTime date;

  ParsedIncome({
    required this.amount,
    required this.source,
    required this.date,
  });
}

// --- Parser ---

class SmsParser {
  static bool isIncomeMessage(String body) {
    final text = body.toLowerCase();
    if (text.contains("debited") ||
        text.contains("dr.") ||
        text.contains("spent") ||
        text.contains("withdrawn")) {
      return false;
    }
    return text.contains("credited") ||
        text.contains("received") ||
        text.contains("deposited") ||
        text.contains("cr.");
  }

  static bool isGigIncome(String body) {
    final text = body.toLowerCase();
    return text.contains("swiggy") ||
        text.contains("zomato") ||
        text.contains("uber") ||
        text.contains("ola") ||
        text.contains("zepto") ||
        text.contains("earnings") ||
        text.contains("payout") ||
        text.contains("settlement");
  }

  static bool isValidGigIncome(String body) {
    return isIncomeMessage(body) && isGigIncome(body);
  }

  static double? extractAmount(String text) {
    final patterns = [
      RegExp(r'₹\s?([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'inr\s?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'rs\.?\s?([\d,]+)', caseSensitive: false),
    ];
    for (var regex in patterns) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(",", "");
        return double.tryParse(raw);
      }
    }
    return null;
  }

  static String extractSource(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("swiggy")) return "Swiggy";
    if (lower.contains("zomato")) return "Zomato";
    if (lower.contains("uber")) return "Uber";
    if (lower.contains("ola")) return "Ola";
    if (lower.contains("zepto")) return "Zepto";
    return "Unknown";
  }

  static DateTime? extractDate(SmsMessage message) {
    final ms = message.date;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static ParsedIncome? parse(SmsMessage message) {
    final body = message.body ?? "";
    if (!isValidGigIncome(body)) return null;
    final amount = extractAmount(body);
    if (amount == null) return null;
    final date = extractDate(message);
    if (date == null) return null;
    return ParsedIncome(amount: amount, source: extractSource(body), date: date);
  }
}

// --- Screen ---

class ReadSmsScreen extends StatefulWidget {
  const ReadSmsScreen({
    super.key,
    this.appBarActions,
  });

  final List<Widget>? appBarActions;

  @override
  State<ReadSmsScreen> createState() => _ReadSmsScreenState();
}

class _ReadSmsScreenState extends State<ReadSmsScreen> {
  final Telephony telephony = Telephony.instance;
  final List<ParsedIncome> _incomes = [];
  TaxIntelligenceResult? _taxResult;

  final _numFmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  double get _totalIncome =>
      _incomes.fold(0.0, (sum, item) => sum + item.amount);

  void _onNewIncome(ParsedIncome income) {
    setState(() {
      _incomes.insert(0, income);
      _taxResult = TaxIntelligence.analyze(_totalIncome);
    });
  }

  void startListening() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final parsed = SmsParser.parse(message);
        if (parsed != null) _onNewIncome(parsed);
      },
      listenInBackground: false,
    );
  }

  // ── Emulator test button ── remove before release
  void _injectTestSms(String body) {
    final amount = SmsParser.extractAmount(body);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parser couldn't extract amount")),
      );
      return;
    }
    _onNewIncome(ParsedIncome(
      amount: amount,
      source: SmsParser.extractSource(body),
      date: DateTime.now(),
    ));
  }

  @override
  void initState() {
    startListening();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gig Income Tracker"),
        actions: widget.appBarActions,
      ),
      body: Column(
        children: [
          // ── Test buttons (emulator only) ──────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _testBtn("Swiggy ₹850",
                    "Your account has been credited with ₹850.00. Payment received from Swiggy settlement."),
                _testBtn("Zomato INR 1200",
                    "INR 1,200.50 credited to your account. Zomato payout for week ending 10-Apr-2025."),
                _testBtn("Uber Rs 450",
                    "Rs. 450 deposited to your a/c. Uber earnings settlement."),
              ],
            ),
          ),

          // ── Total income bar ──────────────────────────────────────
          if (_incomes.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

      appBar: AppBar(
        title: const Text("Gig Income Tracker"),
        actions: widget.appBarActions,
      ),
      body: _incomes.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Test buttons for demo
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _testBtn(
                                "Swiggy ₹850",
                                "Your account has been credited with ₹850.00. Payment received from Swiggy settlement.",
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _testBtn(
                                "Zomato ₹1200",
                                "INR 1,200.50 credited to your account. Zomato payout for week ending 10-Apr-2025.",
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _testBtn(
                                "Uber ₹450",
                                "Rs. 450 deposited to your a/c. Uber earnings settlement.",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Income summary
                        IncomeSummaryCard(
                          count: _incomes.length,
                          total: _totalIncome,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Recent transactions header
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Transaction list
                        ..._incomes.take(5).map((income) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: TransactionCard(
                              source: income.source,
                              amount: income.amount,
                              date: income.date,
                            ),
                          );
                        }),
                        if (_incomes.length > 5) ...[const SizedBox(height: AppSpacing.lg)],
                      ],
                    ),
                  ),
                  // Tax section
                  if (_taxResult != null) ...[_buildTaxSection(_taxResult!)],
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No income tracked yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'We\'ll monitor your SMS and automatically detect income deposits.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Or test with sample transactions:',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _testBtn(
                    "Add Swiggy",
                    "Your account has been credited with ₹850.00. Payment received from Swiggy settlement.",
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _testBtn(
                    "Add Zomato",
                    "INR 1,200.50 credited to your account. Zomato payout for week ending 10-Apr-2025.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSection(TaxIntelligenceResult result) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaxHealthCard(
            grossIncome: result.totalIncome,
            taxableIncome: result.taxableIncome,
            taxPayable: result.taxPayable,
          ),
          if (result.suggestions.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg)],
          if (result.suggestions.isNotEmpty) ...[_buildSuggestionsSection(result)],
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(TaxIntelligenceResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips & Recommendations',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        ...result.suggestions.map((suggestion) {
          final type = _getSuggestionType(suggestion);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SuggestionCard(
              suggestion: suggestion,
              type: type,
            ),
          );
        }),
      ],
    );
  }

  SuggestionType _getSuggestionType(String suggestion) {
    final lower = suggestion.toLowerCase();
    if (lower.contains('rebate') ||
        lower.contains('eligible') ||
        lower.contains('zero')) {
      return SuggestionType.positive;
    }
    if (lower.contains('advance') ||
        lower.contains('warning') ||
        lower.contains('high')) {
      return SuggestionType.warning;
    }
    return SuggestionType.info;
  }

  Widget _testBtn(String label, String sms) {
    return ElevatedButton(
      onPressed: () => _injectTestSms(sms),
      child: Text(label),
    );
  }
}