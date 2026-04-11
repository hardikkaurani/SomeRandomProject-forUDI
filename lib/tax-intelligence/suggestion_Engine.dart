class SuggestionEngine {
  static List<String> generate({
    required double totalIncome,
    required double taxableIncome,
    required double taxPayable,
  }) {
    List<String> suggestions = [];

    // Rule 1: Rebate under 87A
    if (taxableIncome <= 700000) {
      suggestions.add(
        "You may be eligible for rebate under Section 87A — your tax could be zero.",
      );
    }

    // Rule 2: Near rebate threshold
    if (taxableIncome > 700000 && taxableIncome <= 750000) {
      suggestions.add(
        "You're close to the rebate limit. A small investment could reduce your tax to zero.",
      );
    }

    // Rule 3: High income warning (44ADA limit awareness)
    if (totalIncome > 5000000) {
      suggestions.add(
        "Your income is approaching/exceeding the 44ADA applicability range. Consider proper accounting.",
      );
    }

    // Rule 4: Advance tax suggestion
    if (taxPayable > 10000) {
      suggestions.add(
        "You may need to pay advance tax to avoid penalties.",
      );
    }

    // Rule 5: General optimization tip
    suggestions.add(
      "Consider investing in tax-saving instruments like ELSS or PPF.",
    );

    return suggestions;
  }
}