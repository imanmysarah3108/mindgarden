import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up.dart';

// Onboarding page for Mind Garden application
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding slides content
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/mindgarden_logo.png',
      'title': 'Welcome to Mind Garden',
      'description': 'Your personal space to cultivate thoughts and track your well-being.',
    },
    {
      'image': 'assets/onboarding_2.png',
      'title': 'Track Your Moods',
      'description': 'Easily record how you feel each day with simple emojis.',
    },
    {
      'image': 'assets/onboarding_3.png',
      'title': 'Journal Your Journey',
      'description': 'Write down your thoughts, experiences, and reflections.',
    },
    {
      'image': 'assets/onboarding_4.png',
      'title': 'Visualize Your Progress',
      'description': 'See your emotional patterns and writing habits over time.',
    },
  ];

  // Function to navigate to sign up page (used by both Get Started and Skip)
  void _navigateToSignUp() {
    if (mounted) {
      Navigator.of(context).pushReplacement( // Use pushReplacement to clear the onboarding stack
        MaterialPageRoute(builder: (_) => const SignUpPage()), // Navigate to SignUpPage
      );
    }
  }

  // Function to save onboarding completion status
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildOnboardingSlide(
                imagePath: _onboardingData[index]['image']!,
                title: _onboardingData[index]['title']!,
                description: _onboardingData[index]['description']!,
              );
            },
          ),
          // Dot indicators for slider onboarding pages
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => _buildDotIndicator(index == _currentPage),
              ),
            ),
          ),
          // Skip button (top right)
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _navigateToSignUp, // Skip to sign up page
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Get Started button (bottom center on last page)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _currentPage == _onboardingData.length - 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Visibility(
                visible: _currentPage == _onboardingData.length - 1, // Only visible on the last page
                child: ElevatedButton(
                  onPressed: _navigateToSignUp, // Navigate to sign up
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build each onboarding slide
  Widget _buildOnboardingSlide({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 250,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper widget to build dot indicators
  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Function to save onboarding completion status
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
