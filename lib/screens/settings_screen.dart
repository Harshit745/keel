import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _backgroundColor = Color(0xFF0D0D0D);
  static const Color _cardColor = Color(0xFF1A1A1A);
  static const Color _purple = Color(0xFF6C63FF);
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF1DB954);
  static const Color _mutedWhite = Color(0x99FFFFFF);
  static const Color _borderColor = Color(0xFF333333);

  final TextEditingController _nameController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat('#,##,###');

  bool _isLoading = true;
  String _name = '';
  double _dailyBudget = 1000;
  String _goal = '';
  int _age = 20;
  String _email = '';
  bool _notificationsEnabled = true;

  static const List<_GoalSettingOption> _goalOptions = <_GoalSettingOption>[
    _GoalSettingOption(
      value: 'pre_idea',
      title: 'Pre-idea',
      subtitle: 'Exploring and finding problems',
      icon: Icons.explore,
    ),
    _GoalSettingOption(
      value: 'pre_revenue',
      title: 'Pre-revenue',
      subtitle: 'Building before customers',
      icon: Icons.construction,
    ),
    _GoalSettingOption(
      value: 'revenue',
      title: 'Revenue stage',
      subtitle: 'Growing with paying customers',
      icon: Icons.attach_money,
    ),
    _GoalSettingOption(
      value: 'scaling',
      title: 'Scaling',
      subtitle: 'Product-market fit and scaling up',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final String name = await UserService.getName();
    final double budget = await UserService.getDailyBudget();
    final String goal = await UserService.getGoal();
    final int age = await UserService.getAge();
    final bool notificationsEnabled =
        await UserService.getNotificationsEnabled();
    final User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    setState(() {
      _name = name;
      _nameController.text = name;
      _dailyBudget = budget;
      _goal = goal;
      _age = age;
      _email = user?.email ?? 'No email';
      _notificationsEnabled = notificationsEnabled;
      _isLoading = false;
    });
  }

  String _formatCurrency(num amount) {
    return '₹${_currencyFormatter.format(amount.round())}';
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'pre_idea':
        return 'Pre-idea';
      case 'pre_revenue':
        return 'Pre-revenue';
      case 'revenue':
        return 'Revenue stage';
      case 'scaling':
        return 'Scaling';
      default:
        return 'Stay consistent';
    }
  }

  Future<void> _showGoalEditor() async {
    String tempGoal = _goal.isEmpty ? 'pre_idea' : _goal;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Founder Stage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Update what stage you are currently in.',
                        style: TextStyle(fontSize: 14, color: _mutedWhite),
                      ),
                      const SizedBox(height: 24),
                      ..._goalOptions.map((option) {
                        final bool isSelected = tempGoal == option.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempGoal = option.value;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _purple : _borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    option.icon,
                                    color: isSelected ? _purple : Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          option.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option.subtitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _mutedWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final NavigatorState nav = Navigator.of(context);
                            await UserService.completeOnboarding(
                              name: _name,
                              goal: tempGoal,
                              dailyBudget: _dailyBudget,
                              age: _age,
                            );
                            if (!mounted) return;
                            setState(() => _goal = tempGoal);
                            nav.pop();
                            _showSnack('Goal updated');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateName() async {
    final String newName = _nameController.text.trim();
    if (newName.length < 2) return;

    await UserService.completeOnboarding(
      name: newName,
      goal: _goal,
      dailyBudget: _dailyBudget,
      age: _age,
    );
    await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

    if (!mounted) return;
    setState(() => _name = newName);
    _showSnack('Name updated');
  }

  Future<void> _showBudgetEditor() async {
    double tempBudget = _dailyBudget;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        'Daily Budget',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _formatCurrency(tempBudget),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: tempBudget,
                        min: 200,
                        max: 5000,
                        divisions: 48,
                        activeColor: _purple,
                        onChanged: (double value) {
                          setModalState(() {
                            tempBudget = value.roundToDouble();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final NavigatorState nav = Navigator.of(context);
                            await UserService.completeOnboarding(
                              name: _name,
                              goal: _goal,
                              dailyBudget: tempBudget,
                              age: _age,
                            );
                            if (!mounted) return;
                            setState(() => _dailyBudget = tempBudget);
                            nav.pop();
                            _showSnack('Budget updated');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Sign out?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Your local data will be preserved, but you\'ll need to sign in again.',
            style: TextStyle(color: _mutedWhite, fontSize: 14),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _mutedWhite)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out', style: TextStyle(color: _red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await AuthService().signOut();
    if (!mounted) return;

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _mutedWhite,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color iconColor = _purple,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor, width: 0.5),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _mutedWhite,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _purple)),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top bar
              SizedBox(
                height: 48,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 48,
                      child: widget.showBackButton
                          ? IconButton(
                              onPressed: () => Navigator.pop(context, true),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Profile section
              _buildSectionHeader('Profile'),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: _name,
                subtitle: _email,
                onTap: () async {
                  _nameController.text = _name;
                  await showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (BuildContext ctx) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 36,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Text(
                                    'Edit Name',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Your name',
                                      hintStyle: const TextStyle(
                                        color: _mutedWhite,
                                      ),
                                      filled: true,
                                      fillColor: _backgroundColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _updateName();
                                        Navigator.pop(ctx);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Preferences section
              _buildSectionHeader('Preferences'),
              _buildSettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Daily Budget',
                subtitle: _formatCurrency(_dailyBudget),
                iconColor: const Color(0xFF00BFA5),
                onTap: _showBudgetEditor,
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.flag_outlined,
                title: 'Goal',
                subtitle: _goalLabel(_goal),
                iconColor: const Color(0xFFF5A623),
                onTap: _showGoalEditor,
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Daily Reminders',
                subtitle: 'Daily mood prompt at 8:00 PM',
                iconColor: const Color(0xFFFF6B35),
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  activeTrackColor: _green,
                  onChanged: (bool value) async {
                    HapticFeedback.lightImpact();
                    await UserService.setNotificationsEnabled(value);
                    if (!mounted) return;
                    setState(() => _notificationsEnabled = value);
                    if (value) {
                      await NotificationService.scheduleDailyMoodPrompt();
                      await NotificationService.scheduleMorningMotivation();
                      _showSnack('Reminders enabled');
                    } else {
                      await NotificationService.cancelDailyReminders();
                      _showSnack('Reminders disabled');
                    }
                  },
                ),
              ),

              // About section
              _buildSectionHeader('About'),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'Keel',
                subtitle: 'v1.0.0',
                iconColor: _mutedWhite,
              ),

              // Sign out
              const SizedBox(height: 32),
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Sign out',
                iconColor: _red,
                onTap: _confirmSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSettingOption {
  const _GoalSettingOption({
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
