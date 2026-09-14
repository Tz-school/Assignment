import 'package:flutter/material.dart';
import '../service/database_service.dart';
import '../model/comparison_model.dart';
import 'app_drawer.dart';

class DataAnalysisPage extends StatefulWidget {
  final String userRole;
  final String username;

  const DataAnalysisPage({
    super.key,
    required this.userRole,
    required this.username,
  });

  @override
  State<DataAnalysisPage> createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  final DatabaseService _dbService = DatabaseService();

  final _tab1FormKey = GlobalKey<FormState>();
  String? _tab1State;
  String? _tab1Sector;
  final TextEditingController _tab1SalaryController = TextEditingController();

  final _tab3FormKey = GlobalKey<FormState>();
  final TextEditingController _tab3SalaryController = TextEditingController();
  double _targetSavingsRate = 30.0;

  bool _showAllStates = false;

  List<ComparisonModel> _list = [];
  bool _isLoadingSaved = false;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, Map<String, double>> _stateData = {
    'Selangor': {'median': 3093.0, 'livingCost': 2100.0, 'gdpPct': 0.265},
    'W.P. Kuala Lumpur': {'median': 3809.0, 'livingCost': 2400.0, 'gdpPct': 0.153},
    'Johor': {'median': 2306.0, 'livingCost': 1800.0, 'gdpPct': 0.098},
    'Sarawak': {'median': 1708.0, 'livingCost': 1600.0, 'gdpPct': 0.088},
    'Pulau Pinang': {'median': 2610.0, 'livingCost': 1900.0, 'gdpPct': 0.075},
    'Perak': {'median': 1638.0, 'livingCost': 1550.0, 'gdpPct': 0.053},
    'Sabah': {'median': 1354.0, 'livingCost': 1550.0, 'gdpPct': 0.051},
    'Pahang': {'median': 1640.0, 'livingCost': 1500.0, 'gdpPct': 0.041},
    'Kedah': {'median': 1432.0, 'livingCost': 1450.0, 'gdpPct': 0.032},
    'Negeri Sembilan': {'median': 1847.0, 'livingCost': 1700.0, 'gdpPct': 0.032},
    'Melaka': {'median': 2148.0, 'livingCost': 1750.0, 'gdpPct': 0.029},
    'Terengganu': {'median': 1584.0, 'livingCost': 1450.0, 'gdpPct': 0.023},
    'Kelantan': {'median': 1218.0, 'livingCost': 1400.0, 'gdpPct': 0.017},
    'W.P. Putrajaya': {'median': 3451.0, 'livingCost': 2300.0, 'gdpPct': 0.008},
    'W.P. Labuan': {'median': 1933.0, 'livingCost': 1950.0, 'gdpPct': 0.005},
    'Perlis': {'median': 1453.0, 'livingCost': 1400.0, 'gdpPct': 0.004},
  };

  final Map<String, double> _sectorMedian = {
    'ICT': 5000.0,
    'Finance': 4500.0,
    'Manufacturing': 3500.0,
    'Construction': 3200.0,
    'Logistics': 3000.0,
  };

  final Map<String, String> _stateClusters = {
    'Selangor': 'Tech and advanced manufacturing',
    'W.P. Kuala Lumpur': 'Finance and professional services',
    'Johor': 'Petrochemical, logistics and data centers',
    'Sarawak': 'Renewable energy and industrial corridors',
    'Pulau Pinang': 'Semiconductors and electronics design',
    'Perak': 'Automotive and mineral processing',
    'Sabah': 'Marine services and agriculture',
    'Pahang': 'Maritime logistics and petrochemical',
    'Kedah': 'Kulim Hi-Tech Park and electronics',
    'Negeri Sembilan': 'Aerospace parts and logistics parks',
    'Melaka': 'Semiconductors and materials',
    'Terengganu': 'Petrochemical and coastal energy',
    'Kelantan': 'Agri-tech and border trading',
    'W.P. Putrajaya': 'Government digital administration',
    'W.P. Labuan': 'Offshore finance and maritime oil',
    'Perlis': 'Solar energy and agro-tech',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _tab1SalaryController.dispose();
    _tab3SalaryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData([String query = '']) async {
    setState(() => _isLoadingSaved = true);
    final data = await _dbService.getComparisons(searchQuery: query);
    setState(() {
      _list = data;
      _isLoadingSaved = false;
    });
  }

  Future<void> _showSaveDialogTab1() async {
    if (!_tab1FormKey.currentState!.validate()) {
      return;
    }

    final double salary = double.parse(_tab1SalaryController.text.trim());
    final titleController = TextEditingController(text: '${_tab1State!} Wage');
    final notesController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Comparison'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final double livingCost = _stateData[_tab1State]?['livingCost'] ?? 1800.0;
      final double netDisposable = salary - livingCost;
      final double savingsRatio = salary > 0 ? (netDisposable / salary) * 100 : 0.0;
      final String finalTitle = titleController.text.trim().isEmpty
          ? '${_tab1State!} Wage'
          : titleController.text.trim();

      final item = ComparisonModel(
        title: finalTitle,
        state: _tab1State!,
        sector: _tab1Sector ?? 'General',
        nominalSalary: salary,
        netDisposable: netDisposable,
        savingsRatio: savingsRatio,
        status: 'Active',
        notes: notesController.text.trim(),
      );

      await _dbService.insertComparison(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSavedData();
    }

    titleController.dispose();
    notesController.dispose();
  }

  Future<void> _showSaveDialogTab3(String targetState, double targetSalary) async {
    final titleController = TextEditingController(text: '$targetState Feasibility Match');
    final notesController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Feasibility Scenario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final double livingCost = _stateData[targetState]?['livingCost'] ?? 1800.0;
      final double netDisposable = targetSalary - livingCost;
      final double savingsRatio = targetSalary > 0 ? (netDisposable / targetSalary) * 100 : 0.0;
      final String finalTitle = titleController.text.trim().isEmpty
          ? '$targetState Feasibility Match'
          : titleController.text.trim();

      final item = ComparisonModel(
        title: finalTitle,
        state: targetState,
        sector: 'Feasibility Match',
        nominalSalary: targetSalary,
        netDisposable: netDisposable,
        savingsRatio: savingsRatio,
        status: 'Active',
        notes: notesController.text.trim(),
      );

      await _dbService.insertComparison(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSavedData();
    }

    titleController.dispose();
    notesController.dispose();
  }

  Future<void> _showEditDialog(ComparisonModel item) async {
    final titleEditController = TextEditingController(text: item.title);
    final salaryEditController = TextEditingController(text: item.nominalSalary.toStringAsFixed(0));
    final notesEditController = TextEditingController(text: item.notes);
    String editStatus = item.status;
    final editFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Record'),
              content: SingleChildScrollView(
                child: Form(
                  key: editFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleEditController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: salaryEditController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Salary (RM)'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty || double.tryParse(value.trim()) == null) {
                            return 'Please enter a valid salary';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: editStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'Active', child: Text('Active')),
                          DropdownMenuItem(value: 'Archived', child: Text('Archived')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => editStatus = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: notesEditController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!editFormKey.currentState!.validate()) {
                      return;
                    }

                    final double updatedSalary = double.parse(salaryEditController.text.trim());
                    final double livingCost = _stateData[item.state]?['livingCost'] ?? 1800.0;
                    final double updatedDisposable = updatedSalary - livingCost;
                    final double updatedRatio = updatedSalary > 0 ? (updatedDisposable / updatedSalary) * 100 : 0.0;

                    final updated = ComparisonModel(
                      id: item.id,
                      title: titleEditController.text.trim(),
                      state: item.state,
                      sector: item.sector,
                      nominalSalary: updatedSalary,
                      netDisposable: updatedDisposable,
                      savingsRatio: updatedRatio,
                      status: editStatus,
                      notes: notesEditController.text.trim(),
                    );

                    await _dbService.updateComparison(updated);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _loadSavedData(_searchController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Record updated.')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleEditController.dispose();
    salaryEditController.dispose();
    notesEditController.dispose();
  }

  String _generateSectorAdvice(String state, String sector, double salary, double sectorMedian) {
    String advice = '';
    if (salary > sectorMedian) {
      advice = 'Salary is higher than the $sector average.';
    } else if (salary < sectorMedian) {
      advice = 'Salary is below the $sector average.';
    } else {
      advice = 'Salary matches the $sector average.';
    }

    final cluster = _stateClusters[state] ?? 'General industries';
    return '$advice ($state focus: $cluster)';
  }

  Widget _buildVarianceBadge(double varianceAmount, double variancePct) {
    final bool isPositive = varianceAmount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPositive ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Text(
        isPositive
            ? '+RM ${varianceAmount.toStringAsFixed(0)} (+${variancePct.toStringAsFixed(1)}%)'
            : '-RM ${(-varianceAmount).toStringAsFixed(0)} (${variancePct.toStringAsFixed(1)}%)',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
        ),
      ),
    );
  }

  Widget _buildStateCard(Map<String, dynamic> item) {
    final String st = item['state'] as String;
    final double net = item['net'] as double;
    final double r = item['ratio'] as double;
    final double salary = item['salary'] as double;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(st, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Cost: RM ${(item['cost'] as double).toStringAsFixed(0)} | Net: RM ${net.toStringAsFixed(0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${r.toStringAsFixed(1)}% savings', style: TextStyle(fontWeight: FontWeight.bold, color: item['statusColor'] as Color)),
                Text(item['statusText'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, size: 20, color: Colors.indigo),
              onPressed: () => _showSaveDialogTab3(st, salary),
              tooltip: 'Save Match',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wage Analysis'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Wage by State & Sector'),
              Tab(text: 'GDP by State'),
              Tab(text: 'State Feasibility Matcher'),
              Tab(text: 'Saved Comparisons'),
            ],
          ),
        ),
        drawer: AppDrawer(userRole: widget.userRole, username: widget.username),
        body: TabBarView(
          children: [
            _buildWageByStateAndSectorTab(),
            _buildGDPByStateTab(),
            _buildStateFeasibilityMatcherTab(),
            _buildSavedComparisonsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWageByStateAndSectorTab() {
    final double stateMedian = _tab1State != null
        ? _stateData[_tab1State]!['median']!
        : 2153.0;
    final double sectorMedian = _tab1Sector != null
        ? _sectorMedian[_tab1Sector]!
        : 3500.0;
    final double? expectedSalary = double.tryParse(_tab1SalaryController.text.trim());

    double stateVariance = 0.0;
    double stateVariancePct = 0.0;
    double sectorVariance = 0.0;
    double sectorVariancePct = 0.0;

    if (expectedSalary != null) {
      stateVariance = expectedSalary - stateMedian;
      if (stateMedian > 0) {
        stateVariancePct = (stateVariance / stateMedian) * 100;
      }
      sectorVariance = expectedSalary - sectorMedian;
      if (sectorMedian > 0) {
        sectorVariancePct = (sectorVariance / sectorMedian) * 100;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _tab1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _tab1State,
                      decoration: const InputDecoration(
                        labelText: 'Select State *',
                        border: OutlineInputBorder(),
                      ),
                      items: _stateData.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _tab1State = val),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _tab1Sector,
                      decoration: const InputDecoration(
                        labelText: 'Select Sector',
                        border: OutlineInputBorder(),
                      ),
                      items: _sectorMedian.keys.map((sec) => DropdownMenuItem(value: sec, child: Text(sec))).toList(),
                      onChanged: (val) => setState(() => _tab1Sector = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tab1SalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expected Salary (RM) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter salary';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'State Median (${_tab1State ?? "National"}): RM ${stateMedian.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        if (expectedSalary != null)
                          _buildVarianceBadge(stateVariance, stateVariancePct),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Sector Median (${_tab1Sector ?? "Industry"}): RM ${sectorMedian.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        if (expectedSalary != null)
                          _buildVarianceBadge(sectorVariance, sectorVariancePct),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (expectedSalary != null) ...[
                      LinearProgressIndicator(
                        value: (expectedSalary / (sectorMedian * 1.5)).clamp(0.0, 1.0),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const Divider(height: 20),
                      const Text('Comment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        _generateSectorAdvice(
                          _tab1State ?? 'Selected State',
                          _tab1Sector ?? 'Selected Sector',
                          expectedSalary,
                          sectorMedian,
                        ),
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ] else ...[
                      const Text('Enter salary to see comparison.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showSaveDialogTab1,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Comparison'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGDPByStateTab() {
    final stateList = _stateData.keys.toList()
      ..sort((a, b) => _stateData[b]!['gdpPct']!.compareTo(_stateData[a]!['gdpPct']!));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          color: Colors.indigo.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const ListTile(
            leading: Icon(Icons.factory_outlined, color: Colors.indigo),
            title: Text('GDP by State', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Percentage share of national GDP by state (2025).'),
          ),
        ),
        const SizedBox(height: 16),
        const Text('GDP Contribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...stateList.map((st) {
          final double gdpPct = _stateData[st]!['gdpPct']!;
          final String cluster = _stateClusters[st] ?? 'General industries';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(st, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${(gdpPct * 100).toStringAsFixed(1)}% of GDP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Focus: $cluster', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (gdpPct / 0.27).clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStateFeasibilityMatcherTab() {
    final double? salary = double.tryParse(_tab3SalaryController.text.trim());

    List<Map<String, dynamic>> meetsTarget = [];
    List<Map<String, dynamic>> belowTarget = [];
    List<Map<String, dynamic>> deficit = [];

    if (salary != null) {
      _stateData.forEach((st, data) {
        final double cost = data['livingCost']!;
        final double net = salary - cost;
        final double ratio = salary > 0 ? (net / salary) * 100 : 0.0;

        String statusText;
        Color statusColor;

        if (net < 0) {
          statusText = 'Deficit';
          statusColor = Colors.red.shade800;
          deficit.add({'state': st, 'cost': cost, 'net': net, 'ratio': ratio, 'statusText': statusText, 'statusColor': statusColor, 'salary': salary});
        } else if (ratio >= _targetSavingsRate) {
          statusText = 'Meets Target';
          statusColor = Colors.green.shade800;
          meetsTarget.add({'state': st, 'cost': cost, 'net': net, 'ratio': ratio, 'statusText': statusText, 'statusColor': statusColor, 'salary': salary});
        } else {
          statusText = 'Below Target';
          statusColor = Colors.orange.shade800;
          belowTarget.add({'state': st, 'cost': cost, 'net': net, 'ratio': ratio, 'statusText': statusText, 'statusColor': statusColor, 'salary': salary});
        }
      });
    }

    Map<String, dynamic>? bestMatch;
    if (meetsTarget.isNotEmpty) {
      bestMatch = meetsTarget.reduce((curr, next) =>
      (curr['net'] as double) > (next['net'] as double) ? curr : next
      );
    } else if (belowTarget.isNotEmpty) {
      bestMatch = belowTarget.reduce((curr, next) =>
      (curr['net'] as double) > (next['net'] as double) ? curr : next
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _tab3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('State Feasibility Matcher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tab3SalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expected Monthly Salary (RM) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter salary';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid salary';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<double>(
                      value: _targetSavingsRate,
                      decoration: const InputDecoration(
                        labelText: 'Target Savings Rate',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 10.0, child: Text('10% Savings Target')),
                        DropdownMenuItem(value: 20.0, child: Text('20% Savings Target')),
                        DropdownMenuItem(value: 30.0, child: Text('30% Savings Target (Recommended)')),
                        DropdownMenuItem(value: 40.0, child: Text('40% High Savings Target')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _targetSavingsRate = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (salary != null) ...[
              Card(
                color: Colors.indigo.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feasibility Summary (${_targetSavingsRate.toStringAsFixed(0)}% Target)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text('• ${meetsTarget.length} states meet or exceed your savings target.'),
                      Text('• ${belowTarget.length} states are below your savings target.'),
                      if (deficit.isNotEmpty)
                        Text('• ${deficit.length} states result in a monthly budget deficit.', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (bestMatch != null) ...[
                Card(
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade300, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommended Best Match',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bestMatch['state']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Estimated Savings Rate: ${(bestMatch['ratio'] as double).toStringAsFixed(1)}% '
                              '(Net RM ${(bestMatch['net'] as double).toStringAsFixed(0)})',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Provides the highest estimated financial retention among evaluated options.',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (meetsTarget.isNotEmpty) ...[
                const Text('States Meeting Your Target', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 4),
                ...meetsTarget.map((item) => _buildStateCard(item)),
                const SizedBox(height: 12),
              ],
              if (belowTarget.isNotEmpty) ...[
                const Text('Below Target', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 4),
                ...belowTarget.map((item) => _buildStateCard(item)),
                const SizedBox(height: 12),
              ],
              if (deficit.isNotEmpty) ...[
                const Text('Budget Deficit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 4),
                ...deficit.map((item) => _buildStateCard(item)),
              ],
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Enter your expected salary above to evaluate state feasibility.', style: TextStyle(color: Colors.blueGrey)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavedComparisonsTab() {
    final int totalCount = _list.length;
    ComparisonModel? optimalItem;
    ComparisonModel? suboptimalItem;
    double gap = 0.0;

    if (totalCount > 0) {
      optimalItem = _list.reduce((a, b) => a.netDisposable > b.netDisposable ? a : b);
      suboptimalItem = _list.reduce((a, b) => a.netDisposable < b.netDisposable ? a : b);
      gap = optimalItem.netDisposable - suboptimalItem.netDisposable;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildComparisonStat('Scenarios', totalCount.toString()),
                  _buildComparisonStat(
                    'Best Net',
                    optimalItem != null ? 'RM ${optimalItem.netDisposable.toStringAsFixed(0)}' : 'RM 0',
                  ),
                  _buildComparisonStat(
                    'Lowest Net',
                    suboptimalItem != null ? 'RM ${suboptimalItem.netDisposable.toStringAsFixed(0)}' : 'RM 0',
                  ),
                  _buildComparisonStat('Net Gap', 'RM ${gap.toStringAsFixed(0)}'),
                ],
              ),
              if (optimalItem != null && suboptimalItem != null && totalCount > 1) ...[
                const SizedBox(height: 6),
                Text(
                  'Best option: ${optimalItem.state} has RM ${gap.toStringAsFixed(0)} more net balance than ${suboptimalItem.state}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (val) => _loadSavedData(val.trim()),
          ),
        ),
        Expanded(
          child: _isLoadingSaved
              ? const Center(child: CircularProgressIndicator())
              : _list.isEmpty
              ? const Center(child: Text('No saved comparisons.'))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _list.length,
            itemBuilder: (context, index) {
              final item = _list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.state} | ${item.sector}'),
                      Text('Salary: RM ${item.nominalSalary.toStringAsFixed(0)} | Net: RM ${item.netDisposable.toStringAsFixed(0)}'),
                      Text(
                        'Savings: ${item.savingsRatio.toStringAsFixed(1)}% | Status: ${item.status}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.status == 'Active' ? Colors.green.shade800 : Colors.blueGrey,
                        ),
                      ),
                      if (item.notes.isNotEmpty)
                        Text('Notes: ${item.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          if (item.id == null) return;
                          final bool? confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Delete Record'),
                                content: Text('Are you sure you want to delete "${item.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            await _dbService.deleteComparison(item.id!);
                            _loadSavedData(_searchController.text.trim());
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Record deleted.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}