class Course {
  const Course({
    required this.id,
    required this.name,
    required this.career,
    required this.years,
    required this.tuition,
    required this.salary,
    required this.demand,
    required this.growth,
    required this.tags,
    required this.preparation,
  });
  final String id, name, career, preparation;
  final int years;

  final double tuition, salary, demand, growth;
  final Set<String> tags;
}

class QuizQuestion {
  const QuizQuestion(this.id, this.title, this.options);
  final String id, title;
  final Map<String, String> options;
}

class CareerGoal {
  CareerGoal({
    required this.id,
    required this.courseId,
    required this.title,
    required this.salary,
    required this.targetDate,
    this.done = false,
  });
  final String id, courseId, title;
  final double salary;
  final DateTime targetDate;
  bool done;
  Map<String, Object?> toDatabase(String username) => {
    'username': username,
    'id': id,
    'courseId': courseId,
    'title': title,
    'salary': salary,
    'targetDate': targetDate.toIso8601String(),
    'done': done ? 1 : 0,
  };
  factory CareerGoal.fromDatabase(Map<String, Object?> row) => CareerGoal(
    id: row['id'] as String,
    courseId: row['courseId'] as String,
    title: row['title'] as String,
    salary: (row['salary'] as num).toDouble(),
    targetDate: DateTime.parse(row['targetDate'] as String),
    done: row['done'] == 1,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'salary': salary,
    'targetDate': targetDate.toIso8601String(),
    'done': done,
  };
  factory CareerGoal.fromJson(Map<String, dynamic> j) => CareerGoal(
    id: j['id'] as String,
    courseId: j['courseId'] as String,
    title: j['title'] as String,
    salary: (j['salary'] as num).toDouble(),
    targetDate: DateTime.parse(j['targetDate'] as String),
    done: j['done'] as bool? ?? false,
  );
}

class Projection {
  const Projection({
    required this.investment,
    required this.monthlySurplus,
    required this.balanceByYear,
    required this.paybackYears,
  });
  final double investment, monthlySurplus;

  final List<double> balanceByYear;
  final double? paybackYears;
  double get netAfter15Years => balanceByYear.last;
}

class CareerScore {
  const CareerScore(this.course, this.suitability, this.financial, this.total);
  final Course course;
  final double suitability, financial, total;
}

class WageBenchmark {
  const WageBenchmark(this.state, this.median, this.mean);
  final String state;
  final double median, mean;
}
