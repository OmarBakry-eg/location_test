import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../animations/fade_animation.dart';
import '../../components/glass_container.dart';
import '../../providers/home_provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(
      builder: (_) => const Dashboard(),
      fullscreenDialog: true,
    );
  }

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Consumer<HomeProvider>(
        builder: (_, homeProvider, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.fastOutSlowIn,
              child: homeProvider.selectedScreen,
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButtonAnimator:
                FloatingActionButtonAnimator.noAnimation,
            floatingActionButton: FadeAnimation(
              duration: 0.4,
              visible: !keyboardOpen,
              child: GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                borderRadius: BorderRadius.circular(30),
                padding: EdgeInsets.zero,
                child: BottomNavigationBar(
                  elevation: 0,
                  selectedFontSize: 0,
                  unselectedFontSize: 0,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: homeProvider.currentIndex,
                  onTap: homeProvider.switchToIndex,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.home,
                      ),
                      activeIcon: GlowingIcon(
                        child: Icon(
                          Icons.home_filled,
                        ),
                      ),
                      label: 'Main',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.book_outlined,
                      ),
                      activeIcon: GlowingIcon(
                        child: Icon(
                          Icons.book,
                        ),
                      ),
                      label: 'Second',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GlowingIcon extends StatelessWidget {
  final Widget child;

  const GlowingIcon({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}
