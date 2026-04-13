import 'tax_engine.dart';
import 'suggestion_engine.dart';
import 'formatter.dart';

class TaxIntelligenceResult {
  final double totalIncome;
  final double taxableIncome;
  final double taxPayable;
  final List<String> suggestions;
  final String summary;

  TaxIntelligenceResult({
    required this.totalIncome,
    required this.taxableIncome,
    required this.taxPayable,
    required this.suggestions,
    required this.summary,
  });
}

class TaxIntelligence {
  static TaxIntelligenceResult analyze(double totalIncome) {
    // Step 1: Calculate tax
    final taxResult = TaxEngine.calculate(totalIncome);

    // Step 2: Generate suggestions
    final suggestions = SuggestionEngine.generate(
      totalIncome: taxResult.totalIncome,
      taxableIncome: taxResult.taxableIncome,
      taxPayable: taxResult.taxPayable,
    );

    // Step 3: Generate summary
    final summary = Formatter.generateSummary(
      totalIncome: taxResult.totalIncome,
      taxableIncome: taxResult.taxableIncome,
      taxPayable: taxResult.taxPayable,
      suggestions: suggestions,
    );

    // Step 4: Return final structured result
    return TaxIntelligenceResult(
      totalIncome: taxResult.totalIncome,
      taxableIncome: taxResult.taxableIncome,
      taxPayable: taxResult.taxPayable,
      suggestions: suggestions,
      summary: summary,
    );
  }
}