class TaxResult {
  final double totalIncome;
  final double taxableIncome;
  final double taxPayable;

  TaxResult({
    required this.totalIncome,
    required this.taxableIncome,
    required this.taxPayable,
  });
}

class TaxEngine {
  static TaxResult calculate(double totalIncome) {
    // Step 1: Apply 44ADA (50% rule)
    double taxableIncome = totalIncome * 0.5;

    double tax = 0;

    // Step 2: Apply tax slabs
    if (taxableIncome <= 300000) {
      tax = 0;
    } else if (taxableIncome <= 600000) {
      tax = (taxableIncome - 300000) * 0.05;
    } else if (taxableIncome <= 900000) {
      tax = 15000 + (taxableIncome - 600000) * 0.10;
    } else if (taxableIncome <= 1200000) {
      tax = 45000 + (taxableIncome - 900000) * 0.15;
    } else if (taxableIncome <= 1500000) {
      tax = 90000 + (taxableIncome - 1200000) * 0.20;
    } else {
      tax = 150000 + (taxableIncome - 1500000) * 0.30;
    }

    return TaxResult(
      totalIncome: totalIncome,
      taxableIncome: taxableIncome,
      taxPayable: tax,
    );
  }
}