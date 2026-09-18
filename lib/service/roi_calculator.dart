class RoiInputs {
  const RoiInputs({
    required this.studyYears,
    required this.horizon,
    required this.tuition,
    required this.studyIncome,
    required this.studyLiving,
    required this.workLiving,
    required this.graduateSalary,
    required this.directSalary,
    required this.graduateGrowth,
    required this.directGrowth,
    required this.inflation,
    required this.discount,
  });
  final int studyYears, horizon;
  final double tuition,
      studyIncome,
      studyLiving,
      workLiving,
      graduateSalary,
      directSalary,
      graduateGrowth,
      directGrowth,
      inflation,
      discount;
  Map<String, dynamic> toJson() => {
    'studyYears': studyYears,
    'horizon': horizon,
    'tuition': tuition,
    'studyIncome': studyIncome,
    'studyLiving': studyLiving,
    'workLiving': workLiving,
    'graduateSalary': graduateSalary,
    'directSalary': directSalary,
    'graduateGrowth': graduateGrowth,
    'directGrowth': directGrowth,
    'inflation': inflation,
    'discount': discount,
  };
  factory RoiInputs.fromJson(Map<String, dynamic> data) {
    final value = RoiInputs(
      studyYears: data['studyYears'] as int,
      horizon: data['horizon'] as int,
      tuition: (data['tuition'] as num).toDouble(),
      studyIncome: (data['studyIncome'] as num).toDouble(),
      studyLiving: (data['studyLiving'] as num).toDouble(),
      workLiving: (data['workLiving'] as num).toDouble(),
      graduateSalary: (data['graduateSalary'] as num).toDouble(),
      directSalary: (data['directSalary'] as num).toDouble(),
      graduateGrowth: (data['graduateGrowth'] as num).toDouble(),
      directGrowth: (data['directGrowth'] as num).toDouble(),
      inflation: (data['inflation'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
    );
    value.validate();
    return value;
  }
  RoiInputs withSalary(double salary) =>
      RoiInputs.fromJson({...toJson(), 'graduateSalary': salary});
  void validate() {
    if (studyYears < 1 ||
        studyYears > 8 ||
        horizon <= studyYears ||
        horizon > 40) {
      throw const FormatException(
        'Study duration must be 1–8 years, and the comparison period must be longer, up to 40 years.',
      );
    }
    for (final value in [
      tuition,
      studyIncome,
      studyLiving,
      workLiving,
      graduateSalary,
      directSalary,
    ]) {
      if (!value.isFinite || value < 0 || value > 10000000) {
        throw const FormatException(
          'Amounts must be between 0 and RM 10,000,000.',
        );
      }
    }
    for (final value in [graduateGrowth, directGrowth, inflation, discount]) {
      if (!value.isFinite || value < 0 || value > 30) {
        throw const FormatException('Rates must be between 0% and 30%.');
      }
    }
  }
}

class RoiYear {
  const RoiYear(
    this.year,
    this.studyNet,
    this.directNet,
    this.difference,
    this.cumulative,
    this.discounted,
  );
  final int year;
  final double studyNet, directNet, difference, cumulative, discounted;
}

class RoiResult {
  const RoiResult(this.years, this.investment, this.npv, this.breakEven);
  final List<RoiYear> years;
  final double investment, npv;
  final double? breakEven;
  double get gain => years.last.cumulative;
  double? get roiPercent => investment > 0 ? gain / investment * 100 : null;
}

class RoiCalculator {
  static double grow(double amount, double rate, int years) {
    var result = amount;
    for (var i = 0; i < years; i++) {
      result *= 1 + rate / 100;
    }
    return result;
  }

  static RoiResult calculate(RoiInputs input, {double salaryFactor = 1}) {
    input.validate();
    if (!salaryFactor.isFinite || salaryFactor < 0 || salaryFactor > 2) {
      throw const FormatException('Invalid salary sensitivity factor.');
    }
    final rows = <RoiYear>[];
    double cumulative = 0, investment = 0, npv = 0;
    double? breakEven;
    bool hadDeficit = false;
    for (var year = 1; year <= input.horizon; year++) {
      final workingCosts = grow(
        input.workLiving * 12,
        input.inflation,
        year - 1,
      );
      final directNet =
          grow(input.directSalary * 12, input.directGrowth, year - 1) -
          workingCosts;
      final studying = year <= input.studyYears;
      final studyNet = studying
          ? input.studyIncome * 12 -
                grow(input.studyLiving * 12, input.inflation, year - 1) -
                input.tuition / input.studyYears
          : grow(
                  input.graduateSalary * salaryFactor * 12,
                  input.graduateGrowth,
                  year - input.studyYears - 1,
                ) -
                workingCosts;
      final difference = studyNet - directNet;
      if (studying && difference < 0) investment -= difference;
      final previous = cumulative;
      cumulative += difference;
      if (cumulative < 0) hadDeficit = true;
      if (hadDeficit &&
          breakEven == null &&
          previous < 0 &&
          cumulative >= 0 &&
          difference > 0) {
        breakEven = year - 1 + (-previous / difference);
      }
      final discounted = difference / grow(1, input.discount, year);
      npv += discounted;
      rows.add(
        RoiYear(year, studyNet, directNet, difference, cumulative, discounted),
      );
    }
    return RoiResult(rows, investment, npv, breakEven);
  }
}

class BudgetResult {
  const BudgetResult(this.surplus, this.remaining, this.months);
  final double surplus, remaining;
  final int? months;
  static BudgetResult calculate({
    required double income,
    required double living,
    required double other,
    required double target,
    required double saved,
  }) {
    for (final value in [income, living, other, target, saved]) {
      if (!value.isFinite || value < 0 || value > 10000000) {
        throw const FormatException('Enter valid non-negative amounts.');
      }
    }
    final surplus = income - living - other;
    final remaining = target > saved ? target - saved : 0.0;
    return BudgetResult(
      surplus,
      remaining,
      remaining == 0
          ? 0
          : surplus > 0
          ? (remaining / surplus).ceil()
          : null,
    );
  }
}
