import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/build_log.dart';
import '../models/self_log.dart';
import '../services/hive_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF111111);
  static const Color _accent = Color(0xFFF0FF00);
  static const Color _muted = Color(0xB3FFFFFF);
  static const Color _border = Color(0xFF333333);

  static const List<double> _budgetQuickPicks = <double>[
    500,
    1000,
    1500,
    2000,
    3000,
  ];

  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _projectFocusNode = FocusNode();
  final FocusNode _priorityFocusNode = FocusNode();
  final NumberFormat _currencyFormatter = NumberFormat('#,##,###');
  final HiveService _hiveService = HiveService();

  int _currentStep = 0;
  double _dailyBudget = 1000;
  bool _isCompleting = false;
  String _selectedGoal = '';
  String? _nameError;
  String? _projectError;
  String? _priorityError;
  String? _goalError;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentStep());
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageUpdate);
    _pageController.dispose();
    _nameController.dispose();
    _projectController.dispose();
    _priorityController.dispose();
    _nameFocusNode.dispose();
    _projectFocusNode.dispose();
    _priorityFocusNode.dispose();
    super.dispose();
  }

  void _handlePageUpdate() {
    final int step = (_pageController.page ?? _currentStep.toDouble()).round();
    if (step != _currentStep && mounted) {
      setState(() => _currentStep = step.clamp(0, 3));
      _focusCurrentStep();
    }
  }

  void _focusCurrentStep() {
    if (_currentStep == 1) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _nameFocusNode.requestFocus();
      });
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _goToStep(int step) async {
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    final String name = _nameController.text.trim();
    final String project = _projectController.text.trim();
    final String priority = _priorityController.text.trim();
    final bool shouldValidateIdentity = _currentStep >= 1;
    final bool shouldValidateGoal = _currentStep >= 2;

    setState(() {
      _nameError = shouldValidateIdentity && name.length < 2
          ? 'Please enter at least 2 characters.'
          : null;
      _projectError = shouldValidateIdentity && project.isEmpty
          ? 'Please enter a project or startup name.'
          : null;
      _priorityError = shouldValidateIdentity && priority.length < 4
          ? 'Name the priority you want Keel to reinforce.'
          : null;
      _goalError = shouldValidateGoal && _selectedGoal.isEmpty
          ? 'Pick one stage to continue.'
          : null;
    });

    return _nameError == null &&
        _projectError == null &&
        _priorityError == null &&
        _goalError == null;
  }

  Future<void> _continue() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 3) {
      await _goToStep(_currentStep + 1);
      return;
    }

    setState(() => _isCompleting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final String trimmedName = _nameController.text.trim();
    final String trimmedProject = _projectController.text.trim();
    final String trimmedPriority = _priorityController.text.trim();

    await UserService.completeOnboarding(
      name: trimmedName,
      goal: _selectedGoal,
      project: trimmedProject,
      currentPriority: trimmedPriority,
      dailyBudget: _dailyBudget,
      age: 20, // default age now that it's removed
    );
    await FirebaseAuth.instance.currentUser?.updateDisplayName(trimmedName);

    final DateTime now = DateTime.now();
    BuildLog? existingBuild = await _hiveService.getBuildLogForDate(now);
    if (existingBuild == null) {
      await _hiveService.saveBuildLog(
        BuildLog(date: now, id: BuildLog.keyForDate(now)),
      );
    }

    SelfLog? existingSelf = await _hiveService.getSelfLogForDate(now);
    if (existingSelf == null) {
      existingSelf = SelfLog(
        date: now,
        id: SelfLog.keyForDate(now),
        dailyBudget: _dailyBudget,
      );
      await _hiveService.saveSelfLog(existingSelf);
    } else {
      existingSelf.dailyBudget = _dailyBudget;
      await _hiveService.saveSelfLog(existingSelf);
    }

    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> r) => false,
    );
  }

  Widget _buildPrimaryButton() {
    final bool isLastStep = _currentStep == 3;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCompleting ? null : _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: _accent.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isCompleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                isLastStep ? 'Start building' : 'Continue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            child: _currentStep == 0
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () => _goToStep(_currentStep - 1),
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(4, (int index) {
                final bool isSelected = index == _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _accent
                        : Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextInputType keyboardType,
    String? errorText,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _muted, fontSize: 16),
        errorText: errorText,
        filled: true,
        fillColor: _card,
        contentPadding: const EdgeInsets.all(18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Spacer(flex: 2),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.25),
              ),
              child: const Icon(Icons.lock, size: 56, color: _accent),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Keel',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Set your operating system for disciplined progress.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.6, color: _muted),
        ),
        const Spacer(flex: 3),
        _buildPrimaryButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNameProjectStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        const Text(
          "What's your name?",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        _buildInputField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          hintText: 'Your first name',
          keyboardType: TextInputType.name,
          errorText: _nameError,
          autofocus: true,
        ),
        const SizedBox(height: 24),
        const Text(
          "What are you building?",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _projectController,
          focusNode: _projectFocusNode,
          hintText: 'Startup / Project name',
          keyboardType: TextInputType.text,
          errorText: _projectError,
        ),
        const SizedBox(height: 24),
        const Text(
          "What matters most right now?",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _priorityController,
          focusNode: _priorityFocusNode,
          hintText: 'Current priority, e.g. ship MVP or fix sleep',
          keyboardType: TextInputType.text,
          errorText: _priorityError,
        ),
        const SizedBox(height: 12),
        const Text(
          'Keel will use this to shape your first-day focus.',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
        const Spacer(),
        _buildPrimaryButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGoalStep() {
    final List<_GoalOption> options = <_GoalOption>[
      _GoalOption(
        value: 'pre_idea',
        title: 'Pre-idea',
        subtitle: 'exploring, finding problems',
        icon: Icons.explore,
      ),
      _GoalOption(
        value: 'pre_revenue',
        title: 'Pre-revenue',
        subtitle: 'building, no customers yet',
        icon: Icons.construction,
      ),
      _GoalOption(
        value: 'revenue',
        title: 'Revenue stage',
        subtitle: 'have customers, growing',
        icon: Icons.attach_money,
      ),
      _GoalOption(
        value: 'scaling',
        title: 'Scaling',
        subtitle: 'product-market fit, scaling up',
        icon: Icons.rocket_launch,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        const Text(
          "What stage are you at?",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final _GoalOption opt = options[index];
              final bool isSelected = _selectedGoal == opt.value;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedGoal = opt.value;
                  _goalError = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _accent : _border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        opt.icon,
                        color: isSelected ? _accent : Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              opt.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              opt.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_goalError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _goalError!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _buildPrimaryButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 24),
        const Text(
          "Baseline self-care guardrail",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "What's your daily limit for personal spending?",
          style: TextStyle(fontSize: 14, color: _muted),
        ),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: <Widget>[
              const Text(
                'Daily Limit',
                style: TextStyle(
                  fontSize: 14,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${_currencyFormatter.format(_dailyBudget.round())}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _accent,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: _bg,
            overlayColor: _accent.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
          ),
          child: Slider(
            value: _dailyBudget,
            max: 5000,
            divisions: 50,
            onChanged: (double val) => setState(() => _dailyBudget = val),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _budgetQuickPicks.map((double amount) {
            final bool isSelected = _dailyBudget == amount;
            return GestureDetector(
              onTap: () => setState(() => _dailyBudget = amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? _accent : _border,
                    width: 1,
                  ),
                ),
                child: Text(
                  '₹${_currencyFormatter.format(amount.round())}',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        _buildPrimaryButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              _buildTopBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _buildWelcomeStep(),
                    _buildNameProjectStep(),
                    _buildGoalStep(),
                    _buildBudgetStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}
