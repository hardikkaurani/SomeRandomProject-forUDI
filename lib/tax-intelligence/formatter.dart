class Formatter {
  static String generateSummary({
    required double totalIncome,
    required double taxableIncome,
    required double taxPayable,
    required List<String> suggestions,
  }) {
    StringBuffer summary = StringBuffer();

    // 1. Income understanding
    summary.writeln(
      "You're earning ₹${totalIncome.toStringAsFixed(0)} from gig work.",
    );

    // 2. 44ADA explanation
    summary.writeln(
      "Under Section 44ADA, only 50% of your income is taxable.",
    );

    summary.writeln(
      "So your taxable income becomes ₹${taxableIncome.toStringAsFixed(0)}.",
    );

    // 3. Tax bracket insight
    String bracket = _getTaxBracket(taxableIncome);

    summary.writeln(
      "You're currently in the $bracket tax bracket.",
    );

    // 4. Tax result
    summary.writeln(
      "Your estimated tax payable is ₹${taxPayable.toStringAsFixed(0)}.",
    );

    // 5. Highlight top suggestion
    if (suggestions.isNotEmpty) {
      summary.writeln("\n💡 Smart Tip:");
      summary.writeln(suggestions.first);
    }

    return summary.toString();
  }

  // Helper function for bracket detection
  static String _getTaxBracket(double income) {
    if (income <= 300000) return "0%";
    if (income <= 600000) return "5%";
    if (income <= 900000) return "10%";
    if (income <= 1200000) return "15%";
    if (income <= 1500000) return "20%";
    return "30%";
  }
}