import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/chat/presentation/contact_sync_screen.dart';
import '../../features/chat/presentation/call_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../models/models.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
    GoRoute(path: '/chat/:roomId', builder: (context, state) => ChatDetailScreen(roomId: state.pathParameters['roomId']!)),
    GoRoute(path: '/contact-sync', builder: (context, state) => const ContactSyncScreen()),
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        return CallScreen(
          sessionId: extra['sessionId'],
          receiverId: extra['receiverId'],
          callType: extra['callType'] as CallType,
          isCaller: extra['isCaller'] as bool,
        );
      },
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
  redirect: (context, state) {
    final session = SupabaseService.auth.currentSession;
    final isLoggingIn = state.matchedLocation == '/' || state.matchedLocation == '/auth';

    if (session == null) {
      return isLoggingIn ? null : '/';
    }

    // User is logged in. Check profile setup completion.
    final hasCompletedProfile = HiveService.instance.isProfileCompleted();

    if (!hasCompletedProfile) {
      // Force setup profile.
      return state.matchedLocation == '/profile-setup' ? null : '/profile-setup';
    }

    // Profile completed. Prevent going back to onboarding/auth.
    if (isLoggingIn || state.matchedLocation == '/profile-setup') {
      return '/chat';
    }

    return null;
  },
);
