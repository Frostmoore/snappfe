import 'package:go_router/go_router.dart';

import '../../features/account/account_gate.dart';
import '../../features/account/account_link_screen.dart';
import '../../features/articles/article_detail_screen.dart';
import '../../features/articles/article_list_screen.dart';
import '../../features/documents/documents_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/sna_login_screen.dart';
import '../../features/auth/sna_password_reset_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/magazine/magazine_screen.dart';
import '../../features/orgchart/orgchart_screen.dart';
import '../../features/partners/partners_screen.dart';
import '../../features/posts/post_detail_screen.dart';
import '../../features/posts/posts_screen.dart';
import '../../features/provincial/provincial_screen.dart';
import '../../features/reserved/reserved_tile_screen.dart';

int _id(GoRouterState s) => int.tryParse(s.pathParameters['id'] ?? '') ?? 0;

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/verify-email', builder: (c, s) => const VerifyEmailScreen()),
    GoRoute(path: '/sna-login', builder: (c, s) => const SnaLoginScreen()),
    GoRoute(path: '/sna-reset', builder: (c, s) => const SnaPasswordResetScreen()),
    GoRoute(path: '/account', builder: (c, s) => const AccountGate()),
    GoRoute(path: '/account/settings', builder: (c, s) => const AccountLinkScreen()),
    GoRoute(path: '/reserved/tiles/:id', builder: (c, s) => ReservedTileScreen(id: _id(s))),

    GoRoute(path: '/posts', builder: (c, s) => const PostsScreen()),
    GoRoute(path: '/posts/:id', builder: (c, s) => PostDetailScreen(id: _id(s))),

    GoRoute(path: '/articles', builder: (c, s) => const ArticleListScreen()),
    GoRoute(path: '/articles/:id', builder: (c, s) => ArticleDetailScreen(id: _id(s))),
    GoRoute(path: '/newsletters', builder: (c, s) => const ArticleListScreen(newsletters: true)),

    GoRoute(path: '/provincial', builder: (c, s) => const ProvincialScreen()),
    GoRoute(path: '/partners', builder: (c, s) => const PartnersScreen()),
    GoRoute(path: '/magazine', builder: (c, s) => const MagazineScreen()),
    GoRoute(path: '/orgchart', builder: (c, s) => const OrgChartScreen()),
    GoRoute(path: '/documents', builder: (c, s) => const DocumentsScreen()),

    GoRoute(path: '/events', builder: (c, s) => const EventsScreen()),
    GoRoute(path: '/events/:id', builder: (c, s) => EventDetailScreen(id: _id(s))),
  ],
);
