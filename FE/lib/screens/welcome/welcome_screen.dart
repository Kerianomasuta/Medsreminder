import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _wave;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  void _finish() {
    if (!mounted || _hasFinished) return;
    _hasFinished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ReferenceLanding(entrance: _entrance, wave: _wave, onStart: _finish);
}

class _ReferenceLanding extends StatelessWidget {
  const _ReferenceLanding({
    required this.entrance,
    required this.wave,
    required this.onStart,
  });

  final Animation<double> entrance;
  final Animation<double> wave;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EAEF6), Color(0xFFB8D5FF), Color(0xFFF1F7FF)],
          stops: [0, .56, 1],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 132,
              right: -76,
              child: _WelcomeOrb(color: Color(0x33FFFFFF), size: 220),
            ),
            const Positioned(
              top: 345,
              left: -80,
              child: _WelcomeOrb(color: Color(0x3388B8FA), size: 190),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: entrance,
                      curve: const Interval(0, .35, curve: Curves.easeOut),
                    ),
                    child: const _LandingNav(),
                  ),
                  const SizedBox(height: 18),
                  _LandingHero(entrance: entrance, wave: wave),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: entrance,
                      curve: const Interval(.4, 1, curve: Curves.easeOut),
                    ),
                    child: const Text(
                      'MedsReminder là dự án hỗ trợ bạn chủ động hơn trong việc dùng thuốc và kết nối với người thân khi cần.',
                      style: TextStyle(
                        color: Color(0xFF18345F),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: entrance,
                      curve: const Interval(.55, 1, curve: Curves.easeOut),
                    ),
                    child: const _LandingHighlights(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: entrance,
                  curve: const Interval(.55, 1, curve: Curves.easeOut),
                ),
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF082452),
                    minimumSize: const Size.fromHeight(55),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Khám phá MedsReminder'),
                      SizedBox(width: 9),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LandingNav extends StatelessWidget {
  const _LandingNav();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 6),
      const Text(
        'MedsReminder',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      const Spacer(),
      const Text(
        'Giới thiệu',
        style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 11),
      ),
      const SizedBox(width: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: const BoxDecoration(
          color: Color(0xFF082452),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: const Text(
          'Bắt đầu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _LandingHero extends StatelessWidget {
  const _LandingHero({required this.entrance, required this.wave});

  final Animation<double> entrance;
  final Animation<double> wave;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 455,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 366,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: entrance,
              curve: const Interval(.2, .8, curve: Curves.easeOut),
            ),
            child: const Text(
              'An tâm mỗi ngày\nvới một lời nhắc nhỏ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF082452),
                fontSize: 29,
                height: .98,
                letterSpacing: -.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position:
            Tween<Offset>(
              begin: const Offset(.08, .1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: entrance, curve: Curves.easeOutBack),
            ),
            child: RotationTransition(
              turns: Tween<double>(
                begin: -.012,
                end: .012,
              ).animate(CurvedAnimation(parent: wave, curve: Curves.easeInOut)),
              child: Center(
                child: Image.asset(
                  'assets/images/welcome_doctor_3d.png',
                  height: 350,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 260,
          child: Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.78),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163F7D).withOpacity(.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7',
                  style: TextStyle(
                    color: Color(0xFF082452),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Đồng hành\ncùng sức khoẻ',
                  style: TextStyle(
                    color: Color(0xFF466182),
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(left: 8, top: 275, child: _HeroStamp()),
      ],
    ),
  );
}

class _HeroStamp extends StatelessWidget {
  const _HeroStamp();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -.22,
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5277A9), width: 1.2),
      ),
      child: const Icon(
        Icons.medication_rounded,
        color: Color(0xFF294D83),
        size: 23,
      ),
    ),
  );
}

class _LandingHighlights extends StatelessWidget {
  const _LandingHighlights();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.68),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(.54)),
    ),
    child: const Row(
      children: [
        Expanded(
          child: _LandingHighlight(
            icon: Icons.alarm_rounded,
            label: 'Nhắc thuốc',
          ),
        ),
        _HighlightDivider(),
        Expanded(
          child: _LandingHighlight(
            icon: Icons.favorite_rounded,
            label: 'Người thân',
          ),
        ),
        _HighlightDivider(),
        Expanded(
          child: _LandingHighlight(
            icon: Icons.local_pharmacy_rounded,
            label: 'Đơn thuốc',
          ),
        ),
      ],
    ),
  );
}

class _LandingHighlight extends StatelessWidget {
  const _LandingHighlight({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFF133B70), size: 22),
      const SizedBox(height: 6),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF234C80),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _HighlightDivider extends StatelessWidget {
  const _HighlightDivider();

  @override
  Widget build(BuildContext context) =>
       Container(width: 1, height: 38, color: const Color(0x3355739F));
}

class _WelcomeOrb extends StatelessWidget {
  const _WelcomeOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
