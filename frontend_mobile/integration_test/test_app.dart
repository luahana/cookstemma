import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// A simplified test app for integration testing.
/// This bypasses Firebase, Isar, and other external dependencies.
class TestApp extends StatelessWidget {
  final bool startAuthenticated;
  final List<Override>? overrides;

  const TestApp({
    super.key,
    this.startAuthenticated = false,
    this.overrides,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Test App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            routerConfig: _createTestRouter(startAuthenticated),
          );
        },
      ),
    );
  }
}

GoRouter _createTestRouter(bool isAuthenticated) {
  return GoRouter(
    initialLocation: isAuthenticated ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _TestHomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const _TestLoginScreen(),
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const _TestRecipeListScreen(),
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _TestRecipeDetailScreen(recipeId: id);
        },
      ),
      GoRoute(
        path: '/logs',
        builder: (context, state) => const _TestLogListScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const _TestProfileScreen(),
      ),
    ],
  );
}

// Test Screens
class _TestHomeScreen extends StatelessWidget {
  const _TestHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
            onTap: () => context.push('/recipes/recipe-$index'),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/recipes');
              break;
            case 2:
              context.go('/logs');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

class _TestLoginScreen extends StatelessWidget {
  const _TestLoginScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sign in to continue'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestRecipeListScreen extends StatelessWidget {
  const _TestRecipeListScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.builder(
          itemCount: 20,
          itemBuilder: (context, index) => Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.restaurant),
              ),
              title: Text('Recipe $index'),
              subtitle: Text('by Chef $index'),
              onTap: () => context.push('/recipes/recipe-$index'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestRecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const _TestRecipeDetailScreen({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recipe $recipeId')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.restaurant, size: 64)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe $recipeId',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('A delicious recipe description goes here.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestLogListScreen extends StatelessWidget {
  const _TestLogListScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cooking Logs')),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          final outcomes = ['SUCCESS', 'PARTIAL', 'FAILED'];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: index % 3 == 0
                    ? Colors.green[100]
                    : index % 3 == 1
                        ? Colors.yellow[100]
                        : Colors.red[100],
                child: Text(
                  index % 3 == 0
                      ? '😊'
                      : index % 3 == 1
                          ? '🙂'
                          : '😅',
                ),
              ),
              title: Text('Log Entry $index'),
              subtitle: Text(outcomes[index % 3]),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TestProfileScreen extends StatelessWidget {
  const _TestProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Test User',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('@testuser'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat('Recipes', '12'),
                    const SizedBox(width: 32),
                    _buildStat('Logs', '45'),
                    const SizedBox(width: 32),
                    _buildStat('Followers', '100'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 9,
              itemBuilder: (context, index) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.restaurant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
