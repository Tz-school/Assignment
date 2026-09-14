import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/career_planner_model.dart';
export '../model/career_planner_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_drawer.dart';
import '../service/career_planner_database.dart';

const courses = <Course>[
  Course(
    id: 'cs',
    name: 'Computer Science',
    career: 'Software Developer',
    years: 3,
    tuition: 36000,
    salary: 3400,
    demand: 85,
    growth: 0.05,
    tags: {'technology', 'logic', 'math', 'office'},
    preparation: 'Build a small app and practise programming fundamentals.',
  ),
  Course(
    id: 'engineering',
    name: 'Electrical Engineering',
    career: 'Electrical Engineer',
    years: 4,
    tuition: 44000,
    salary: 3300,
    demand: 78,
    growth: 0.045,
    tags: {'technology', 'practical', 'science', 'field'},
    preparation: 'Build a circuit project and research accredited programmes.',
  ),
  Course(
    id: 'business',
    name: 'Business Administration',
    career: 'Business Analyst',
    years: 3,
    tuition: 30000,
    salary: 2900,
    demand: 72,
    growth: 0.04,
    tags: {'business', 'logic', 'math', 'office'},
    preparation: 'Practise spreadsheets and analyse a small business case.',
  ),
  Course(
    id: 'design',
    name: 'Digital Design',
    career: 'UX Designer',
    years: 3,
    tuition: 39000,
    salary: 3000,
    demand: 70,
    growth: 0.045,
    tags: {'creative', 'creative_skill', 'arts', 'flexible'},
    preparation: 'Create a portfolio with three design projects.',
  ),
  Course(
    id: 'education',
    name: 'Education',
    career: 'Educator',
    years: 4,
    tuition: 24000,
    salary: 2700,
    demand: 65,
    growth: 0.03,
    tags: {'people', 'communication', 'languages', 'community'},
    preparation: 'Try peer tutoring and check teaching pathway requirements.',
  ),
  Course(
    id: 'health',
    name: 'Nursing',
    career: 'Nurse',
    years: 4,
    tuition: 40000,
    salary: 2800,
    demand: 82,
    growth: 0.035,
    tags: {'people', 'practical', 'science', 'community'},
    preparation:
        'Explore care work and check programme and registration requirements.',
  ),
];
const locationCosts = <String, double>{
  'Kuala Lumpur': 2100,
  'Penang': 1750,
  'Johor Bahru': 1700,
  'Ipoh': 1350,
  'Kuching': 1500,
  'Kota Kinabalu': 1650,
};
const quizQuestions = <QuizQuestion>[
  QuizQuestion('interest', '1. Which activity interests you most?', {
    'Building digital tools': 'technology',
    'Helping people learn or recover': 'people',
    'Running a business': 'business',
    'Creating visual experiences': 'creative',
  }),
  QuizQuestion('skill', '2. Which skill do you enjoy using?', {
    'Solving logical problems': 'logic',
    'Hands-on practical work': 'practical',
    'Explaining ideas to others': 'communication',
    'Designing original work': 'creative_skill',
  }),
  QuizQuestion('subject', '3. Which school subject do you prefer?', {
    'Mathematics': 'math',
    'Science': 'science',
    'Languages': 'languages',
    'Art and design': 'arts',
  }),
  QuizQuestion('preference', '4. What work setting appeals to you?', {
    'An office or analytical team': 'office',
    'Sites, labs or equipment': 'field',
    'A creative, flexible environment': 'flexible',
    'Direct community service': 'community',
  }),
  QuizQuestion('project', '5. Which project would you volunteer for?', {
    'Create an app for students': 'technology',
    'Organise a mentoring session': 'people',
    'Plan a small online shop': 'business',
    'Design a campaign poster': 'creative',
  }),
  QuizQuestion('challenge', '6. How do you prefer to solve a new problem?', {
    'Break it into logical steps': 'logic',
    'Build and test a prototype': 'practical',
    'Discuss it and explain possible solutions': 'communication',
    'Sketch several original ideas': 'creative_skill',
  }),
  QuizQuestion(
    'learning',
    '7. Which topic would you explore in your free time?',
    {
      'Patterns, statistics and numbers': 'math',
      'How the physical world works': 'science',
      'Writing, reading and languages': 'languages',
      'Colour, form and visual storytelling': 'arts',
    },
  ),
  QuizQuestion('routine', '8. Which working day sounds most satisfying?', {
    'Focused analysis with an office team': 'office',
    'Testing equipment in a lab or on site': 'field',
    'Switching between creative projects': 'flexible',
    'Working directly with a community': 'community',
  }),
  QuizQuestion('impact', '9. What kind of contribution motivates you?', {
    'Make useful technology accessible': 'technology',
    'Support personal wellbeing and learning': 'people',
    'Improve how an organisation operates': 'business',
    'Make experiences clearer and more engaging': 'creative',
  }),
  QuizQuestion('team_role', '10. Which team task would you choose?', {
    'Check the reasoning and evidence': 'logic',
    'Assemble and test the solution': 'practical',
    'Present the team’s findings': 'communication',
    'Develop the visual concept': 'creative_skill',
  }),
  QuizQuestion('workshop', '11. Which workshop would you attend?', {
    'Data and mathematical modelling': 'math',
    'Scientific experiments': 'science',
    'Language and storytelling': 'languages',
    'Illustration and design': 'arts',
  }),
  QuizQuestion('placement', '12. Where would you like to try a placement?', {
    'An analytics or software office': 'office',
    'An engineering site or laboratory': 'field',
    'A creative studio': 'flexible',
    'A school or community organisation': 'community',
  }),
];
List<String> roadmapFor(Course c) => [
  'High school: review subjects, entry requirements and your interests.',
  'Before applying: compare fees, scholarships and recognised programmes.',
  'University entry: enrol in ${c.name} and set a study budget.',
  'During ${c.years} years of study: ${c.preparation}',
  'Internship: apply for supervised experience relevant to ${c.career}.',
  'Employment: prepare your CV and apply for ${c.career} roles.',
];

class CareerEngine {
  static double suitability(Course c, Map<String, String> answers) {
    if (answers.length != quizQuestions.length ||
        quizQuestions.any((q) => !q.options.values.contains(answers[q.id]))) {
      throw ArgumentError('Complete all 12 quiz questions first.');
    }
    return quizQuestions.where((q) => c.tags.contains(answers[q.id])).length /
        quizQuestions.length *
        100;
  }

  static Projection project({
    required Course course,
    required double salary,
    required double livingCost,
    required double tuition,
    required double studentLivingCost,
    double foregoneMonthlyPay = 0,
    double? salaryGrowth,
    double costGrowth = 0.025,
  }) {
    final growth = salaryGrowth ?? course.growth;
    for (final n in [
      salary,
      livingCost,
      tuition,
      studentLivingCost,
      foregoneMonthlyPay,
    ]) {
      if (!n.isFinite || n < 0) {
        throw ArgumentError('Amounts must be finite and non-negative.');
      }
    }
    if (course.years <= 0 ||
        !growth.isFinite ||
        growth <= -1 ||
        growth > 1 ||
        !costGrowth.isFinite ||
        costGrowth <= -1 ||
        costGrowth > 1) {
      throw ArgumentError('Invalid duration or annual growth.');
    }
    final investment =
        tuition + (studentLivingCost + foregoneMonthlyPay) * course.years * 12;
    var balance = -investment;
    final balances = <double>[balance];
    double? payback = investment == 0 ? 0 : null;
    for (var year = 0; year < 15; year++) {
      final income = salary * math.pow(1 + growth, year);
      final expenses = livingCost * math.pow(1 + costGrowth, year);
      final surplus = (income - expenses) * 12;
      if (payback == null &&
          balance < 0 &&
          surplus > 0 &&
          balance + surplus >= 0) {
        payback = year + (-balance / surplus);
      }
      balance += surplus;
      balances.add(balance);
    }
    return Projection(
      investment: investment,
      monthlySurplus: salary - livingCost,
      balanceByYear: List.unmodifiable(balances),
      paybackYears: payback,
    );
  }

  static List<CareerScore> rank(
    Map<String, String> answers,
    double livingCost, {
    double? monthlySalary,
  }) {
    final scores = courses.map((c) {
      final fit = suitability(c, answers);
      final p = project(
        course: c,
        salary: monthlySalary ?? c.salary,
        livingCost: livingCost,
        tuition: c.tuition,
        studentLivingCost: livingCost,
      );
      final financial = (p.netAfter15Years / 600000 * 100)
          .clamp(0.0, 100.0)
          .toDouble();
      return CareerScore(
        c,
        fit,
        financial,
        0.45 * fit + 0.30 * financial + 0.25 * c.demand,
      );
    }).toList();
    scores.sort((a, b) {
      final comparison = b.total.compareTo(a.total);
      return comparison != 0 ? comparison : a.course.id.compareTo(b.course.id);
    });
    return scores;
  }
}

class PlannerStore extends ChangeNotifier {
  PlannerStore({
    this.username = 'local',
    this._readValue,
    this._writeValue,
    CareerPlannerDatabase? database,
    this.legacyRead,
  }) : _database = database ?? CareerPlannerDatabase();
  final CareerPlannerDatabase _database;
  final Future<String?> Function(String)? legacyRead;
  final String username;
  final Future<String?> Function(String)? _readValue;
  final Future<void> Function(String, String)? _writeValue;
  Future<void> get saved => _pending;
  double deductionRate = 15;
  Map<String, String> scenario = {};
  double takeHomeFor(String city) => estimatedTakeHome(city, deductionRate);
  void setDeduction(double value) {
    if (!value.isFinite || value < 0 || value > 60) {
      throw ArgumentError('Invalid deductions');
    }
    deductionRate = value;
    save();
  }

  void saveScenario(Map<String, String> value) {
    scenario = Map.of(value);
    save();
  }

  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String get storageKey =>
      'siswa_kerja.module4.v2.${Uri.encodeComponent(username)}';
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  Map<String, String> answers = {};
  String courseId = courses.first.id;
  String location = locationCosts.keys.first;
  final Set<String> milestones = {};
  final List<CareerGoal> goals = [];
  String? storageError;
  Future<void> _pending = Future.value();
  bool _writesBlocked = false;
  Course get selectedCourse => courses.firstWhere((c) => c.id == courseId);
  bool get quizComplete =>
      quizQuestions.every((q) => q.options.values.contains(answers[q.id]));
  double get livingCost => locationCosts[location]!;
  bool isDone(int i) => milestones.contains('$courseId:$i');
  double get progress =>
      List.generate(
        roadmapFor(selectedCourse).length,
        isDone,
      ).where((done) => done).length /
      roadmapFor(selectedCourse).length;
  Future<void> load() async {
    try {
      var raw =
          await (_readValue?.call(storageKey) ?? _database.read(username));
      var migrating = false;
      if (raw == null && _readValue == null) {
        raw =
            await (legacyRead?.call(storageKey) ??
                _preferences.getString(storageKey));
        migrating = raw != null;
      }
      if (raw == null) return;
      _applyData(jsonDecode(raw) as Map<String, dynamic>);
      if (migrating) await _database.write(username, jsonEncode(data));
      storageError = null;
      _writesBlocked = false;
    } catch (_) {
      storageError =
          'Saved progress could not be loaded. Retry saving replaces it with current progress.';
      _writesBlocked = true;
    }
  }

  int revision = 0;
  Set<String> skills = {};
  Map<String, String> interviewAnswers = {};
  void setSkill(String id, bool done) {
    if (done) {
      skills.add(id);
    } else {
      skills.remove(id);
    }
    save();
  }

  void saveInterview(String id, String answer) {
    interviewAnswers[id] = answer.trim();
    save();
  }

  Map<String, dynamic> get data => {
    'skills': skills.toList(),
    'interviewAnswers': interviewAnswers,
    'deductionRate': deductionRate,
    'scenario': scenario,
    'answers': answers,
    'courseId': courseId,
    'location': location,
    'milestones': milestones.toList(),
    'goals': goals.map((g) => g.toJson()).toList(),
  };

  void _applyData(Map<String, dynamic> data) {
    final savedAnswers = Map<String, String>.from(data['answers'] as Map);
    final savedGoals = (data['goals'] as List)
        .map((g) => CareerGoal.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList();
    final savedMilestones = Set<String>.from(data['milestones'] as List);
    if (savedAnswers.entries.any(
          (entry) => !quizQuestions.any(
            (q) => q.id == entry.key && q.options.values.contains(entry.value),
          ),
        ) ||
        !courses.any((c) => c.id == data['courseId']) ||
        !locationCosts.containsKey(data['location']) ||
        savedGoals.any(
          (g) =>
              !courses.any((c) => c.id == g.courseId) ||
              g.targetDate.year < 2000 ||
              g.targetDate.year >= 2200 ||
              !g.salary.isFinite ||
              g.salary < 0 ||
              g.title.trim().isEmpty,
        )) {
      throw const FormatException('Invalid saved data.');
    }
    final rate = (data['deductionRate'] as num?)?.toDouble() ?? 15;
    if (!rate.isFinite || rate < 0 || rate > 60) {
      throw const FormatException('Invalid deductions');
    }
    final savedScenario = Map<String, String>.from(
      data['scenario'] as Map? ?? {},
    );
    if (savedGoals.map((g) => g.id).toSet().length != savedGoals.length ||
        savedGoals.any(
          (g) =>
              g.id.isEmpty ||
              g.id.length > 100 ||
              g.title.length > 100 ||
              g.salary > 100000,
        ) ||
        savedMilestones.any(
          (m) => !courses.any(
            (c) => List.generate(
              roadmapFor(c).length,
              (i) => '${c.id}:$i',
            ).contains(m),
          ),
        )) {
      throw const FormatException('Invalid goals or milestones.');
    }
    const limits = {
      'salary': 100000,
      'living': 100000,
      'tuition': 10000000,
      'student': 100000,
      'foregone': 100000,
      'growth': 30,
      'inflation': 30,
    };
    for (final entry in savedScenario.entries) {
      if (entry.key == 'courseId' && courses.any((c) => c.id == entry.value)) {
        continue;
      }
      if (entry.key == 'city' && locationCosts.containsKey(entry.value)) {
        continue;
      }
      final value = double.tryParse(entry.value);
      if (!limits.containsKey(entry.key) ||
          value == null ||
          !value.isFinite ||
          value < 0 ||
          value > limits[entry.key]!) {
        throw const FormatException('Invalid scenario.');
      }
    }
    final savedSkills = Set<String>.from(data['skills'] as List? ?? []);
    final savedInterviews = Map<String, String>.from(
      data['interviewAnswers'] as Map? ?? {},
    );
    if (savedSkills.any(
          (id) => !courses.any(
            (c) => List.generate(
              skillItems(c).length,
              (i) => '${c.id}:$i',
            ).contains(id),
          ),
        ) ||
        savedInterviews.entries.any(
          (e) => !interviewPrompts.containsKey(e.key) || e.value.length > 5000,
        )) {
      throw const FormatException('Invalid skills or interview drafts.');
    }
    skills = savedSkills;
    interviewAnswers = savedInterviews;
    answers = savedAnswers;
    deductionRate = rate;
    scenario = savedScenario;
    courseId = data['courseId'] as String;
    location = data['location'] as String;
    goals
      ..clear()
      ..addAll(savedGoals);
    milestones
      ..clear()
      ..addAll(savedMilestones);
  }

  String exportBackup() => const JsonEncoder.withIndent('  ').convert({
    'format': 'siswa-kerja-planner',
    'version': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'data': data,
  });

  Map<String, dynamic> validateBackup(String raw) {
    try {
      if (raw.length > 2000000) throw const FormatException();
      final backup = jsonDecode(raw) as Map<String, dynamic>;
      if (backup['format'] != 'siswa-kerja-planner' || backup['version'] != 1) {
        throw const FormatException();
      }
      final candidate = Map<String, dynamic>.from(backup['data'] as Map);
      final validator = PlannerStore();
      try {
        validator._applyData(candidate);
      } finally {
        validator.dispose();
      }
      return candidate;
    } catch (_) {
      throw const FormatException(
        'This is not a valid version 1 planner backup. Existing progress has not changed.',
      );
    }
  }

  void restoreBackup(String raw) {
    final candidate = validateBackup(raw);
    _applyData(candidate);
    revision++;
    _writesBlocked = false;
    save();
  }

  void resetProgress() {
    skills.clear();
    interviewAnswers.clear();
    answers.clear();
    goals.clear();
    milestones.clear();
    scenario.clear();
    deductionRate = 15;
    courseId = courses.first.id;
    location = locationCosts.keys.first;
    revision++;
    _writesBlocked = false;
    save();
  }

  List<CareerGoal> queryGoals({
    String query = '',
    String status = 'All',
    String sort = 'Deadline',
    DateTime? now,
  }) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final needle = query.trim().toLowerCase();
    final results = goals.where((g) {
      final career = courses.firstWhere((c) => c.id == g.courseId).career;
      final matchesText = '${g.title} $career'.toLowerCase().contains(needle);
      final matchesStatus = switch (status) {
        'Active' => !g.done,
        'Completed' => g.done,
        'Overdue' => !g.done && g.targetDate.isBefore(today),
        'Due soon' =>
          !g.done &&
              !g.targetDate.isBefore(today) &&
              g.targetDate.isBefore(today.add(const Duration(days: 8))),
        _ => true,
      };
      return matchesText && matchesStatus;
    }).toList();
    results.sort((a, b) {
      final order = switch (sort) {
        'Salary' => b.salary.compareTo(a.salary),
        'Title' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        _ => a.targetDate.compareTo(b.targetDate),
      };
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return results;
  }

  void selectCourse(String id) {
    courseId = id;
    save();
  }

  void selectLocation(String value) {
    location = value;
    save();
  }

  void answer(String id, String value) {
    answers[id] = value;
    save();
  }

  void toggleMilestone(int i, bool done) {
    final key = '$courseId:$i';
    if (done) {
      milestones.add(key);
    } else {
      milestones.remove(key);
    }
    save();
  }

  void putGoal(CareerGoal goal) {
    final i = goals.indexWhere((g) => g.id == goal.id);
    if (i < 0) {
      goals.add(goal);
    } else {
      goals[i] = goal;
    }
    save();
  }

  void removeGoal(String id) {
    goals.removeWhere((g) => g.id == id);
    save();
  }

  void retrySave() {
    _writesBlocked = false;
    save();
  }

  void save() {
    notifyListeners();
    if (_writesBlocked) return;
    final snapshot = jsonEncode(data);

    _pending = _pending.then((_) async {
      try {
        await (_writeValue?.call(storageKey, snapshot) ??
            _database.write(username, snapshot));
        storageError = null;
      } catch (_) {
        storageError =
            'Changes could not be saved on this device. Retry saving.';
      }
      notifyListeners();
    });
  }
}

String rm(num value) {
  final digits = value
      .abs()
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '${value < 0 ? '-' : ''}RM $digits';
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(subtitle),
      ],
    ),
  );
}

class Pick extends StatelessWidget {
  const Pick({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: options.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    this.maximum = 10000000,
  });
  final TextEditingController controller;
  final String label;
  final double maximum;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final n = double.tryParse(value?.trim() ?? '');
        if (n == null || !n.isFinite || n < 0 || n > maximum) {
          return 'Enter 0 to ${maximum.toStringAsFixed(0)} without commas.';
        }
        return null;
      },
    ),
  );
}

Map<String, String> get courseOptions => {
  for (final c in courses) c.id: c.name,
};
Map<String, String> get cityOptions => {
  for (final city in locationCosts.keys) city: city,
};
const demoNote =
    'DOSM 2024 state wages are official benchmarks for employees, not graduate or course-specific salaries. Tuition, living costs, demand and growth are illustrative assumptions.';
String dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';
String paybackLabel(Projection p) => p.paybackYears == null
    ? 'Not recovered within 15 years'
    : '${p.paybackYears!.toStringAsFixed(1)} working years';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.store, required this.onResults});
  final PlannerStore store;
  final VoidCallback onResults;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  bool review = false;
  @override
  void initState() {
    super.initState();
    final unanswered = quizQuestions.indexWhere(
      (q) => !widget.store.answers.containsKey(q.id),
    );
    index = unanswered < 0 ? 0 : unanswered;
    review = widget.store.quizComplete;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final q = quizQuestions[index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'Discover your career fit',
          'Explore your interests, strengths, learning preferences and work environment.',
        ),
        Text(
          '${store.answers.length} of ${quizQuestions.length} answered • Progress saved automatically',
        ),
        LinearProgressIndicator(
          value: store.answers.length / quizQuestions.length,
        ),
        const SizedBox(height: 16),
        if (review) ...[
          const Text('Review your answers. Tap any answer to change it.'),
          for (final question in quizQuestions)
            ListTile(
              title: Text(question.title),
              subtitle: Text(
                question.options.entries
                        .where((e) => e.value == store.answers[question.id])
                        .map((e) => e.key)
                        .firstOrNull ??
                    'Not answered',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => setState(() {
                index = quizQuestions.indexOf(question);
                review = false;
              }),
            ),
        ] else ...[
          Text(
            'Question ${index + 1} of ${quizQuestions.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Panel(
              key: ValueKey(q.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  for (final entry in q.options.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ChoiceChip(
                        label: Text(entry.key),
                        selected: store.answers[q.id] == entry.value,
                        onSelected: (_) {
                          store.answer(q.id, entry.value);
                          setState(() {});
                        },
                      ),
                    ),
                  if (store.answers.containsKey(q.id))
                    const Text('Answer saved. Continue when you are ready.'),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: index > 0 ? () => setState(() => index--) : null,
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: store.answers.containsKey(q.id)
                    ? () => setState(() {
                        if (index == quizQuestions.length - 1) {
                          review = true;
                        } else {
                          index++;
                        }
                      })
                    : null,
                child: Text(
                  index == quizQuestions.length - 1
                      ? 'Review answers'
                      : 'Next question',
                ),
              ),
              TextButton(
                onPressed: () => setState(() => review = true),
                child: const Text('View all answers'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: store.quizComplete ? widget.onResults : null,
          child: const Text('See recommended careers and courses'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Each answer contributes equally to your match score. This is an exploratory self-reflection quiz, not a validated aptitude assessment.',
        ),
      ],
    );
  }
}

List<String> skillItems(Course course) => [
  course.preparation,
  'Explain a ${course.career} project clearly in two minutes.',
  'Prepare a CV with evidence of your relevant skills.',
  'Practise teamwork and describe your contribution to a group project.',
  'Research entry requirements and identify one next learning opportunity.',
];

const interviewPrompts = <String, String>{
  'introduction': 'Tell me about yourself and the career you want to pursue.',
  'problem': 'Describe a time you solved a difficult problem.',
  'teamwork': 'Tell me about a team project and your contribution.',
  'learning': 'Describe feedback you received and how you acted on it.',
  'motivation': 'Why are you interested in this role, and what will you bring?',
};

class SkillsBuilderScreen extends StatelessWidget {
  const SkillsBuilderScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) {
    final items = skillItems(store.selectedCourse);
    final done = List.generate(
      items.length,
      (i) => '${store.courseId}:$i',
    ).where(store.skills.contains).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'Build your career readiness',
          'Choose a pathway, practise each task and mark the evidence you have prepared.',
        ),
        Pick(
          label: 'Skills pathway',
          value: store.courseId,
          options: courseOptions,
          onChanged: store.selectCourse,
        ),
        const SizedBox(height: 16),
        Text('$done of ${items.length} readiness tasks completed'),
        LinearProgressIndicator(value: done / items.length),
        const SizedBox(height: 12),
        const Text(
          'These are suggested preparation tasks, not professional certification requirements. Each pathway keeps its own checklist.',
        ),
        for (var i = 0; i < items.length; i++)
          Panel(
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text(items[i]),
                  contentPadding: EdgeInsets.zero,
                  value: store.skills.contains('${store.courseId}:$i'),
                  onChanged: (value) =>
                      store.setSkill('${store.courseId}:$i', value ?? false),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: const Text('Make a 30-day goal'),
                  onPressed: () {
                    final title =
                        'Readiness task ${i + 1}: ${store.selectedCourse.career}';
                    if (store.goals.any(
                      (g) =>
                          g.courseId == store.courseId &&
                          g.title == title &&
                          !g.done,
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'An active goal for this task already exists.',
                          ),
                        ),
                      );
                      return;
                    }
                    store.putGoal(
                      CareerGoal(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        courseId: store.courseId,
                        title: title,
                        salary: store.takeHomeFor(store.location),
                        targetDate: DateUtils.dateOnly(
                          DateTime.now().add(const Duration(days: 30)),
                        ),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Added to Goal Tracker. You can edit its deadline and target salary there.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InterviewPracticeScreen extends StatefulWidget {
  const InterviewPracticeScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  State<InterviewPracticeScreen> createState() =>
      _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  String prompt = interviewPrompts.keys.first;
  late final TextEditingController answer;
  bool showGuide = false;
  @override
  void initState() {
    super.initState();
    answer = TextEditingController(
      text: widget.store.interviewAnswers[prompt] ?? '',
    );
  }

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Heading(
        'Practise your interview answers',
        'Draft an answer, use the coaching checklist and refine your examples.',
      ),
      Text(
        '${widget.store.interviewAnswers.values.where((v) => v.trim().isNotEmpty).length} of ${interviewPrompts.length} prompts drafted',
      ),
      Pick(
        label: 'Practice prompt',
        value: prompt,
        options: {
          for (final entry in interviewPrompts.entries) entry.key: entry.value,
        },
        onChanged: (value) => setState(() {
          prompt = value;
          answer.text = widget.store.interviewAnswers[value] ?? '';
          showGuide = false;
        }),
      ),
      const SizedBox(height: 16),
      Text(
        interviewPrompts[prompt]!,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      TextField(
        controller: answer,
        minLines: 5,
        maxLines: 12,
        maxLength: 5000,
        decoration: const InputDecoration(
          labelText: 'Your practice answer',
          alignLabelWithHint: true,
        ),
        onChanged: (value) {
          widget.store.saveInterview(prompt, value);
          setState(() {});
        },
      ),
      const Text(
        'Drafts save automatically with your planner. These are personal practice notes; they are not submitted to employers.',
      ),
      Text(
        '${answer.text.trim().isEmpty ? 0 : answer.text.trim().split(RegExp(r'\s+')).length} words',
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Show coaching guide'),
        onPressed: () => setState(() => showGuide = !showGuide),
      ),
      if (showGuide)
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt == 'introduction' || prompt == 'motivation'
                    ? 'Connect your current studies, a concrete achievement and your reason for choosing this career.'
                    : 'Use STAR: describe the Situation, your Task, the Action you took and the Result. Explain what you learned.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Self-check: Is the example specific? Is your contribution clear? Is the outcome supported by evidence? Could you explain it aloud without reading?',
              ),
              const Text(
                'This guide does not grade your answer or predict hiring outcomes.',
              ),
            ],
          ),
        ),
    ],
  );
}

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String left = courses[0].id, right = courses[1].id;
  DataRow row(String label, String a, String b) => DataRow(
    cells: [DataCell(Text(label)), DataCell(Text(a)), DataCell(Text(b))],
  );
  @override
  Widget build(BuildContext context) {
    final a = courses.firstWhere((c) => c.id == left),
        b = courses.firstWhere((c) => c.id == right);
    final living = widget.store.livingCost;
    Projection project(Course c) => CareerEngine.project(
      course: c,
      salary: widget.store.takeHomeFor(widget.store.location),
      livingCost: living,
      tuition: c.tuition,
      studentLivingCost: living,
    );
    final pa = project(a), pb = project(b);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'Compare your options',
          'Compare two sample university-course pathways in the same location.',
        ),
        Pick(
          label: 'First course',
          value: left,
          options: courseOptions,
          onChanged: (v) => setState(() {
            if (v == right) right = left;
            left = v;
          }),
        ),
        Pick(
          label: 'Second course',
          value: right,
          options: Map.fromEntries(
            courseOptions.entries.where((e) => e.key != left),
          ),
          onChanged: (v) => setState(() => right = v),
        ),
        Pick(
          label: 'Living-cost location',
          value: widget.store.location,
          options: cityOptions,
          onChanged: widget.store.selectLocation,
        ),
        OfficialWageCard(
          city: widget.store.location,
          deductionRate: widget.store.deductionRate,
          onDeductionChanged: widget.store.setDeduction,
        ),
        Panel(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Measure')),
                DataColumn(label: Text(a.name)),
                DataColumn(label: Text(b.name)),
              ],
              rows: [
                row('Career', a.career, b.career),
                row('Study duration', '${a.years} years', '${b.years} years'),
                row('Total tuition', rm(a.tuition), rm(b.tuition)),
                row(
                  'Estimated state baseline take-home pay',
                  rm(widget.store.takeHomeFor(widget.store.location)),
                  rm(widget.store.takeHomeFor(widget.store.location)),
                ),
                row(
                  'Job demand (demo index)',
                  '${a.demand.round()}/100',
                  '${b.demand.round()}/100',
                ),
                row('Monthly living costs', rm(living), rm(living)),
                row(
                  'Annual pay growth assumption',
                  '${(a.growth * 100).toStringAsFixed(1)}%',
                  '${(b.growth * 100).toStringAsFixed(1)}%',
                ),
                row(
                  'Education investment',
                  rm(pa.investment),
                  rm(pb.investment),
                ),
                row(
                  '15 working-year net balance',
                  rm(pa.netAfter15Years),
                  rm(pb.netAfter15Years),
                ),
                row(
                  'Recovery after graduation',
                  paybackLabel(pa),
                  paybackLabel(pb),
                ),
              ],
            ),
          ),
        ),
        const Text(
          'Swipe the table horizontally on a small screen. Investment includes tuition and living costs '
          'during study. Working expenses grow 2.5% annually. The horizon is 15 working years, '
          'so total time from enrolment varies by course.',
        ),
        const SizedBox(height: 12),
        const Text(demoNote),
      ],
    );
  }
}

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  Widget build(BuildContext context) {
    final steps = roadmapFor(store.selectedCourse);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'One milestone at a time',
          'Your pathway from high school to employment.',
        ),
        Pick(
          label: 'My course pathway',
          value: store.courseId,
          options: courseOptions,
          onChanged: store.selectCourse,
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Metric('Target career', store.selectedCourse.career),
              LinearProgressIndicator(value: store.progress, minHeight: 10),
              const SizedBox(height: 10),
              Text('${(store.progress * 100).round()}% complete'),
            ],
          ),
        ),
        for (var i = 0; i < steps.length; i++)
          Card(
            child: CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(steps[i]),
              subtitle: Text('Milestone ${i + 1} of ${steps.length}'),
              value: store.isDone(i),
              onChanged: (v) => store.toggleMilestone(i, v ?? false),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Progress is saved separately for each course. '
          'Check admission, accreditation and registration requirements with the institution.',
        ),
      ],
    );
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  PlannerStore get store => widget.store;
  String query = '', status = 'All', sort = 'Deadline';
  Future<void> edit(BuildContext context, [CareerGoal? goal]) async {
    final result = await showDialog<CareerGoal>(
      context: context,
      builder: (_) => GoalDialog(store: store, goal: goal),
    );
    if (result != null) store.putGoal(result);
  }

  @override
  Widget build(BuildContext context) {
    final completed = store.goals.where((g) => g.done).length;
    final visible = store.queryGoals(query: query, status: status, sort: sort);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'Make your ambitions measurable',
          'Save a career goal, target salary and deadline.',
        ),
        FilledButton.icon(
          onPressed: () => edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Add career goal'),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$completed of ${store.goals.length} goals completed'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: store.goals.isEmpty ? 0 : completed / store.goals.length,
              ),
            ],
          ),
        ),
        if (store.goals.isEmpty)
          const Panel(
            child: Text('No goals yet. Try: Secure my first internship.'),
          ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search goals or careers',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        Pick(
          label: 'Goal status',
          value: status,
          options: {
            for (final value in [
              'All',
              'Active',
              'Completed',
              'Overdue',
              'Due soon',
            ])
              value: value,
          },
          onChanged: (value) => setState(() => status = value),
        ),
        const SizedBox(height: 12),
        Pick(
          label: 'Sort goals',
          value: sort,
          options: {
            for (final value in ['Deadline', 'Salary', 'Title']) value: value,
          },
          onChanged: (value) => setState(() => sort = value),
        ),
        Text('${visible.length} matching goals'),
        if (visible.isEmpty && store.goals.isNotEmpty)
          const Panel(
            child: Text(
              'No matching goals. Change your search or status filter.',
            ),
          ),
        for (final goal in visible)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(goal.title),
                  value: goal.done,
                  onChanged: (v) {
                    goal.done = v ?? false;
                    store.save();
                  },
                ),
                Text(courses.firstWhere((c) => c.id == goal.courseId).career),
                Metric('Target monthly take-home salary', rm(goal.salary)),
                Text('Target date: ${dateLabel(goal.targetDate)}'),
                if (!goal.done &&
                    goal.targetDate.isBefore(
                      DateUtils.dateOnly(DateTime.now()),
                    ))
                  const Text(
                    'Past target date - review your plan',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => edit(context, goal),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete this goal?'),
                            content: Text(goal.title),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Keep'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) store.removeGoal(goal.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class GoalDialog extends StatefulWidget {
  const GoalDialog({super.key, required this.store, this.goal});
  final PlannerStore store;
  final CareerGoal? goal;
  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, salary;
  late String courseId;
  late DateTime date;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.goal?.title ?? '');
    salary = TextEditingController(
      text: (widget.goal?.salary ?? 3500).toStringAsFixed(0),
    );
    courseId = widget.goal?.courseId ?? widget.store.courseId;
    date =
        widget.goal?.targetDate ??
        DateUtils.dateOnly(DateTime.now().add(const Duration(days: 365)));
  }

  @override
  void dispose() {
    title.dispose();
    salary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.goal == null ? 'New career goal' : 'Edit career goal'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Goal'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your goal.' : null,
              ),
              const SizedBox(height: 12),
              Pick(
                label: 'Career pathway',
                value: courseId,
                options: courseOptions,
                onChanged: (v) => setState(() => courseId = v),
              ),
              AmountField(
                controller: salary,
                label: 'Target monthly take-home pay (RM)',
                maximum: 100000,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Target: ${dateLabel(date)}'),
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2199, 12, 31),
                  );
                  if (selected != null && mounted) {
                    setState(() => date = selected);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(
            context,
            CareerGoal(
              id:
                  widget.goal?.id ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              courseId: courseId,
              title: title.text.trim(),
              salary: double.parse(salary.text.trim()),
              targetDate: date,
              done: widget.goal?.done ?? false,
            ),
          );
        },
        child: const Text('Save goal'),
      ),
    ],
  );
}

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key, required this.store, required this.onQuiz});
  final PlannerStore store;
  final VoidCallback onQuiz;
  @override
  Widget build(BuildContext context) {
    if (!store.quizComplete) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Heading(
            'Your personalized ranking',
            'Complete the quiz to include your personal suitability.',
          ),
          FilledButton(
            onPressed: onQuiz,
            child: const Text('Take the suitability quiz'),
          ),
        ],
      );
    }
    final ranked = CareerEngine.rank(
      store.answers,
      store.livingCost,
      monthlySalary: store.takeHomeFor(store.location),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'Explore your strongest matches',
          'State wage benchmarks, your interests and transparent simulation assumptions.',
        ),
        Pick(
          label: 'Location for financial comparison',
          value: store.location,
          options: cityOptions,
          onChanged: store.selectLocation,
        ),
        OfficialWageCard(
          city: store.location,
          deductionRate: store.deductionRate,
          onDeductionChanged: store.setDeduction,
        ),
        const Panel(
          child: Text(
            'Score = 45% personal fit + 30% financial potential + 25% job demand. '
            'Each matching answer adds 100/12 fit points across 12 equally weighted questions. All courses share the selected state wage baseline after assumed deductions. Financial potential is the 15-year net balance '
            'divided by RM 600,000, capped between 0 and 100. Demand is a sample index. '
            'This ranking is a planning aid, not a prediction.',
          ),
        ),
        for (var i = 0; i < ranked.length; i++)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${i + 1}  ${ranked[i].course.career}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(ranked[i].course.name),
                Metric(
                  'Overall career score',
                  '${ranked[i].total.toStringAsFixed(1)} / 100',
                ),
                LinearProgressIndicator(
                  value: ranked[i].total / 100,
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  'Personal fit ${ranked[i].suitability.round()} | Financial ${ranked[i].financial.round()} | '
                  'Demand ${ranked[i].course.demand.round()}',
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    store.selectCourse(ranked[i].course.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Path selected. Open Career Roadmap to track milestones.',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    store.courseId == ranked[i].course.id
                        ? 'Current pathway'
                        : 'Use this pathway',
                  ),
                ),
              ],
            ),
          ),
        const Text(demoNote),
      ],
    );
  }
}

class WhatIfScreen extends StatefulWidget {
  const WhatIfScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  final form = GlobalKey<FormState>();
  late String courseId, city;
  final salary = TextEditingController(), living = TextEditingController();
  final tuition = TextEditingController(), student = TextEditingController();
  final foregone = TextEditingController(text: '0'),
      growth = TextEditingController();
  final inflation = TextEditingController(text: '2.5');
  Projection? result, baseline;
  String? resultLabel;
  bool dirty = true;
  Course get course => courses.firstWhere((c) => c.id == courseId);
  @override
  void initState() {
    super.initState();
    courseId = widget.store.courseId;
    city = widget.store.location;
    courseDefaults();
    cityDefaults();
    final saved = widget.store.scenario;
    if (courses.any((c) => c.id == saved['courseId']) &&
        locationCosts.containsKey(saved['city'])) {
      courseId = saved['courseId']!;
      city = saved['city']!;
      final controllers = {
        'salary': salary,
        'living': living,
        'tuition': tuition,
        'student': student,
        'foregone': foregone,
        'growth': growth,
        'inflation': inflation,
      };
      for (final entry in controllers.entries) {
        if (saved[entry.key] != null) entry.value.text = saved[entry.key]!;
      }
    }
  }

  void courseDefaults() {
    salary.text = widget.store.takeHomeFor(city).toStringAsFixed(0);
    tuition.text = course.tuition.toStringAsFixed(0);
    growth.text = (course.growth * 100).toStringAsFixed(1);
  }

  void cityDefaults() {
    living.text = locationCosts[city]!.toStringAsFixed(0);
    student.text = living.text;
  }

  @override
  void dispose() {
    for (final c in [
      salary,
      living,
      tuition,
      student,
      foregone,
      growth,
      inflation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double n(TextEditingController c) => double.parse(c.text.trim());
  void calculate() {
    if (!form.currentState!.validate()) return;
    widget.store.saveScenario({
      'courseId': courseId,
      'city': city,
      'salary': salary.text,
      'living': living.text,
      'tuition': tuition.text,
      'student': student.text,
      'foregone': foregone.text,
      'growth': growth.text,
      'inflation': inflation.text,
    });
    setState(() {
      result = CareerEngine.project(
        course: course,
        salary: n(salary),
        livingCost: n(living),
        tuition: n(tuition),
        studentLivingCost: n(student),
        foregoneMonthlyPay: n(foregone),
        salaryGrowth: n(growth) / 100,
        costGrowth: n(inflation) / 100,
      );
      baseline = CareerEngine.project(
        course: course,
        salary: widget.store.takeHomeFor(city),
        livingCost: locationCosts[city]!,
        tuition: course.tuition,
        studentLivingCost: locationCosts[city]!,
      );
      resultLabel = '${course.name} in $city';
      dirty = false;
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Heading(
        'What if your plans change?',
        'Change assumptions, then calculate a 15-year working-life scenario.',
      ),
      OfficialWageCard(
        city: city,
        deductionRate: widget.store.deductionRate,
        onDeductionChanged: (value) {
          widget.store.setDeduction(value);
          setState(() {
            salary.text = widget.store.takeHomeFor(city).toStringAsFixed(0);
            dirty = true;
          });
        },
      ),
      Form(
        key: form,
        onChanged: () {
          if (!dirty) setState(() => dirty = true);
        },
        child: Panel(
          child: Column(
            children: [
              Pick(
                label: 'Course (resets pay, fees and pay growth)',
                value: courseId,
                options: courseOptions,
                onChanged: (v) => setState(() {
                  courseId = v;
                  courseDefaults();
                  dirty = true;
                }),
              ),
              Pick(
                label: 'Location (resets pay and living costs)',
                value: city,
                options: cityOptions,
                onChanged: (v) => setState(() {
                  city = v;
                  cityDefaults();
                  salary.text = widget.store
                      .takeHomeFor(city)
                      .toStringAsFixed(0);
                  dirty = true;
                }),
              ),
              AmountField(
                controller: salary,
                label: 'Starting monthly take-home pay (RM)',
                maximum: 100000,
              ),
              AmountField(
                controller: tuition,
                label: 'Total course tuition (RM)',
              ),
              AmountField(
                controller: student,
                label: 'Monthly living cost while studying (RM)',
                maximum: 100000,
              ),
              AmountField(
                controller: living,
                label: 'Monthly living cost while working (RM)',
                maximum: 100000,
              ),
              AmountField(
                controller: foregone,
                label: 'Monthly income forgone while studying (RM)',
                maximum: 100000,
              ),
              AmountField(
                controller: growth,
                label: 'Annual pay growth (%)',
                maximum: 30,
              ),
              AmountField(
                controller: inflation,
                label: 'Annual working living-cost growth (%)',
                maximum: 30,
              ),
              FilledButton.icon(
                onPressed: calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate scenario'),
              ),
            ],
          ),
        ),
      ),
      if (dirty && result != null)
        const Panel(
          child: Text(
            'Inputs changed. Calculate again to update your results.',
          ),
        ),
      if (result != null && !dirty) ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resultLabel!, style: Theme.of(context).textTheme.titleLarge),
              Metric(
                'Education investment including opportunity cost',
                rm(result!.investment),
              ),
              Metric(
                'Starting monthly surplus / deficit',
                rm(result!.monthlySurplus),
              ),
              Metric(
                'Investment recovery after graduation',
                paybackLabel(result!),
              ),
              Metric(
                'Net balance after 15 working years',
                rm(result!.netAfter15Years),
              ),
              Metric(
                'Change versus state benchmark scenario',
                rm(result!.netAfter15Years - baseline!.netAfter15Years),
              ),
              const Text(
                'Baseline uses the official 2024 state median less your assumed deductions, sample tuition, living costs and pay growth, '
                '2.5% expense growth and no forgone income.',
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net balance over time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final year in [0, 1, 3, 5, 10, 15])
                Metric(
                  year == 0 ? 'At graduation' : 'After $year working years',
                  rm(result!.balanceByYear[year]),
                ),
            ],
          ),
        ),
      ],
      const Panel(
        child: Text(
          'Method: investment = tuition + study months x (student living costs + forgone pay). '
          'Each working year adds 12 x (monthly take-home pay - living costs), with annual growth from year two. '
          'Recovery is the first crossing of zero, interpolated within the year; it may reverse if later costs exceed pay. '
          'This is cash-flow recovery, not incremental degree ROI. No loans, interest, discounting, unemployment gaps '
          'or investment returns are modelled. Enter pay after deductions. Study living costs stay constant; amounts are nominal RM.',
        ),
      ),
      const Text(demoNote),
    ],
  );
}

const wageSourceUrl =
    'https://storage.dosm.gov.my/labour/salaries_wages_2024.pdf';
const wageBenchmarks = <String, WageBenchmark>{
  'Kuala Lumpur': WageBenchmark('W.P. Kuala Lumpur', 3687, 4782),
  'Penang': WageBenchmark('Pulau Pinang', 2934, 3787),
  'Johor Bahru': WageBenchmark('Johor', 2582, 3414),
  'Ipoh': WageBenchmark('Perak', 2050, 3172),
  'Kuching': WageBenchmark('Sarawak', 2490, 3424),
  'Kota Kinabalu': WageBenchmark('Sabah', 2236, 3389),
};
double estimatedTakeHome(String city, double deductions) {
  if (!wageBenchmarks.containsKey(city) ||
      !deductions.isFinite ||
      deductions < 0 ||
      deductions > 60) {
    throw ArgumentError('Invalid location or deduction percentage');
  }
  return wageBenchmarks[city]!.median * (1 - deductions / 100);
}

class OfficialWageCard extends StatelessWidget {
  const OfficialWageCard({
    super.key,
    required this.city,
    required this.deductionRate,
    this.onDeductionChanged,
  });
  final String city;
  final double deductionRate;
  final ValueChanged<double>? onDeductionChanged;
  @override
  Widget build(BuildContext context) {
    final b = wageBenchmarks[city]!;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOSM 2024 / ${b.state}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('Median monthly wage: ${rm(b.median)} | Mean: ${rm(b.mean)}'),
          const Text(
            'State-level Malaysian citizen employee wages; not city-level or graduate starting pay.',
          ),
          const SizedBox(height: 8),
          Text(
            'Assumed total deductions: ${deductionRate.toStringAsFixed(0)}%',
          ),
          if (onDeductionChanged != null)
            Slider(
              value: deductionRate,
              min: 0,
              max: 60,
              divisions: 60,
              label: '${deductionRate.round()}%',
              onChanged: onDeductionChanged,
            ),
          Text(
            'Estimated take-home baseline: ${rm(estimatedTakeHome(city, deductionRate))} per month',
          ),
          const Text(
            'Deductions are your scenario assumption, not a tax or payroll calculation. Course and location forecasts are not official statistics.',
          ),
          TextButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Source: DOSM report, Chart 7, page 35'),
            onPressed: () async {
              try {
                final opened = await launchUrl(Uri.parse(wageSourceUrl));
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Source could not be opened. See docs/DATA_SOURCES.md.',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Source could not be opened. See docs/DATA_SOURCES.md.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class PlannerDataScreen extends StatelessWidget {
  const PlannerDataScreen({super.key, required this.store});
  final PlannerStore store;

  Future<bool> confirm(
    BuildContext context,
    String title,
    String message,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> export(BuildContext context) async {
    final raw = store.exportBackup();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planner backup'),
        content: SizedBox(
          width: 560,
          height: 320,
          child: SingleChildScrollView(child: SelectableText(raw)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy backup'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await Clipboard.setData(ClipboardData(text: raw));
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Backup copied. Paste it into a text file and save it.',
                    ),
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Clipboard unavailable. Select and copy the backup text manually.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> restore(BuildContext context) async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => BackupImportDialog(store: store),
    );
    if (raw == null || !context.mounted) return;
    final candidate = store.validateBackup(raw);
    final accepted = await confirm(
      context,
      'Replace planner progress?',
      'Restore ${(candidate['goals'] as List).length} goals, '
          '${(candidate['answers'] as Map).length} quiz answers and '
          '${(candidate['milestones'] as List).length} completed milestones into ${store.username}? '
          'This replaces your current planner, including its saved scenario. Copy a backup first if you want to keep it.',
    );
    if (!accepted || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    store.restoreBackup(raw);
    await store.saved;
    messenger.showSnackBar(
      SnackBar(content: Text(store.storageError ?? 'Planner backup restored.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overdue = store.queryGoals(status: 'Overdue');
    final upcoming = store.queryGoals(status: 'Due soon');
    final active = store.queryGoals(status: 'Active');
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Heading(
          'Manage your planner data',
          'Review progress, back up your plan and restore it on another device.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account: ${store.username}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Stored locally in this browser or device. Backups contain your goals and financial inputs; keep them private. There is no cloud sync.',
              ),
              Metric(
                'Quiz answers',
                '${store.answers.length} / ${quizQuestions.length}',
              ),
              Metric('Career goals', '${store.goals.length}'),
              Metric(
                'Completed goals',
                '${store.goals.where((g) => g.done).length}',
              ),
              Metric(
                'Completed roadmap milestones (all courses)',
                '${store.milestones.length}',
              ),
              Metric(
                'Current course progress',
                '${(store.progress * 100).round()}%',
              ),
              Metric('Overdue goals', '${overdue.length}'),
              Metric('Due today or in the next 7 days', '${upcoming.length}'),
              Metric(
                'Saved scenario',
                store.scenario.isEmpty ? 'None' : 'Available',
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Next steps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!store.quizComplete)
                const Text(
                  'Complete the suitability quiz to unlock personalized career scores.',
                ),
              if (active.isEmpty)
                const Text(
                  'Add a career goal in Goal Tracker to plan your next step.',
                ),
              for (final goal in active.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    overdue.contains(goal)
                        ? Icons.warning_amber
                        : Icons.event_outlined,
                  ),
                  title: Text(goal.title),
                  subtitle: Text('Target: ${dateLabel(goal.targetDate)}'),
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => export(context),
              icon: const Icon(Icons.copy),
              label: const Text('Export backup'),
            ),
            OutlinedButton.icon(
              onPressed: () => restore(context),
              icon: const Icon(Icons.restore),
              label: const Text('Restore backup'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Backups include quiz answers, goals, milestones, skills checklists, interview drafts, course, location, deductions and the last calculated scenario. Login, bookings and other modules are managed separately.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Reset my planner'),
          onPressed: () async {
            final accepted = await confirm(
              context,
              'Reset your planner?',
              'Delete all planner progress for ${store.username} on this device? Export a backup first if you want to restore it later. Other modules and accounts are unaffected.',
            );
            if (!accepted || !context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            store.resetProgress();
            await store.saved;
            messenger.showSnackBar(
              SnackBar(content: Text(store.storageError ?? 'Planner reset.')),
            );
          },
        ),
      ],
    );
  }
}

class BackupImportDialog extends StatefulWidget {
  const BackupImportDialog({super.key, required this.store});
  final PlannerStore store;
  @override
  State<BackupImportDialog> createState() => _BackupImportDialogState();
}

class _BackupImportDialogState extends State<BackupImportDialog> {
  final input = TextEditingController();
  String? error;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Restore planner backup'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the complete JSON text from an exported planner backup.',
            ),
            TextField(
              controller: input,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Backup JSON'),
              autocorrect: false,
              enableSuggestions: false,
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          try {
            widget.store.validateBackup(input.text);
            Navigator.pop(context, input.text);
          } on FormatException catch (e) {
            setState(() => error = e.message);
          }
        },
        child: const Text('Review restore'),
      ),
    ],
  );
}

class CareerPlannerPage extends StatefulWidget {
  const CareerPlannerPage({
    super.key,
    required this.userRole,
    required this.username,
    this.store,
  });
  final String userRole, username;
  final PlannerStore? store;
  @override
  State<CareerPlannerPage> createState() => _CareerPlannerPageState();
}

class _CareerPlannerPageState extends State<CareerPlannerPage>
    with SingleTickerProviderStateMixin {
  late PlannerStore _store;
  late Future<void> _loading;
  late final TabController _tabs;
  bool get _ownsStore => widget.store == null;
  void _initialize() {
    _store = widget.store ?? PlannerStore(username: widget.username);
    _loading = _ownsStore ? _store.load() : Future.value();
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 9, vsync: this);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant CareerPlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username ||
        oldWidget.store != widget.store) {
      if (oldWidget.store == null) _store.dispose();
      _initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsStore) _store.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Smart Career Planner'),
      actions: [
        IconButton(
          tooltip: 'About this planner',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Plan for SDG 9'),
              content: const SingleChildScrollView(
                child: Text(
                  'Explore pathways into digital innovation, engineering and industry-supporting skills. '
                  'Use official 2024 DOSM state wage benchmarks to compare affordability, then track study and internship milestones. '
                  'This supports informed access to industry careers; it does not measure national SDG progress. '
                  'Quiz, fees, living costs, demand and growth are exploratory assumptions. '
                  'Your planner is saved under your signed-in username on this device.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Suitability Quiz'),
          Tab(text: 'Course Simulator'),
          Tab(text: 'Career Roadmap'),
          Tab(text: 'Goal Tracker'),
          Tab(text: 'What-If Simulator'),
          Tab(text: 'Career Score'),
          Tab(text: 'Data Manager'),
          Tab(text: 'Skills Builder'),
          Tab(text: 'Interview Practice'),
        ],
      ),
    ),
    drawer: AppDrawer(userRole: widget.userRole, username: widget.username),
    body: FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return AnimatedBuilder(
          animation: _store,
          builder: (context, _) => Column(
            children: [
              if (_store.storageError != null)
                MaterialBanner(
                  content: Text(_store.storageError!),
                  actions: [
                    TextButton(
                      onPressed: _store.retrySave,
                      child: const Text('Retry saving'),
                    ),
                  ],
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: TabBarView(
                      key: ValueKey((_store.username, _store.revision)),
                      controller: _tabs,
                      children: [
                        QuizScreen(
                          store: _store,
                          onResults: () => _tabs.animateTo(5),
                        ),
                        ComparisonScreen(store: _store),
                        RoadmapScreen(store: _store),
                        GoalsScreen(store: _store),
                        WhatIfScreen(store: _store),
                        RankingScreen(
                          store: _store,
                          onQuiz: () => _tabs.animateTo(0),
                        ),
                        PlannerDataScreen(store: _store),
                        SkillsBuilderScreen(store: _store),
                        InterviewPracticeScreen(store: _store),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
