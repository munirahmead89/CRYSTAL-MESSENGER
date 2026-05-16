import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../services/supabase_service.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
    GoRoute(path: '/chat/:roomId', builder: (context, state) => ChatDetailScreen(roomId: state.pathParameters['roomId']!)),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
  redirect: (context, state) {
    final session = SupabaseService.auth.currentSession;
    final isLoggingIn = state.matchedLocation == '/' || state.matchedLocation == '/auth';
    if (session == null) return isLoggingIn ? null : '/';
    if (isLoggingIn) return '/chat';
    return null;
  },
);
