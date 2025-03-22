import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/welcome_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/blood_donation/blood_donation_screen.dart';
import '../screens/blood_donation/register_blood_donor_screen.dart';
import '../screens/blood_donation/seek_blood_screen.dart';
import '../screens/organ_donation/organ_donation_screen.dart';
import '../screens/organ_donation/register_organ_donor_screen.dart';
import '../screens/organ_donation/seek_organ_screen.dart';
import '../screens/hospital/hospital_search_screen.dart';
import '../screens/doctor_search/doctor_search_screen.dart';
import '../screens/ai_doctor/ai_doctor_screen.dart';
import '../services/auth_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    try {

      final authService = Provider.of<AuthService>(context, listen: false);
      final bool isLoggedIn = authService.isAuthenticated;
      
      final bool isAuthRoute = state.location == '/signin' || 
                                state.location == '/signup' || 
                                state.location == '/welcome';
      
      if (!isLoggedIn && !isAuthRoute) {
        return '/welcome';
      }
      
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }
    }
    catch (e) {
      return '/welcome';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/welcome',
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    // Blood Donation Routes
    GoRoute(
      path: '/blood-donation',
      builder: (context, state) => const BloodDonationScreen(),
    ),
    GoRoute(
      path: '/blood-donation/register',
      builder: (context, state) => const RegisterBloodDonorScreen(),
    ),
    GoRoute(
      path: '/blood-donation/seek',
      builder: (context, state) => const SeekBloodScreen(),
    ),
    // Organ Donation Routes
    GoRoute(
      path: '/organ-donation',
      builder: (context, state) => const OrganDonationScreen(),
    ),
    GoRoute(
      path: '/organ-donation/register',
      builder: (context, state) => const RegisterOrganDonorScreen(),
    ),
    GoRoute(
      path: '/organ-donation/seek',
      builder: (context, state) => const SeekOrganScreen(),
    ),
    // Hospital Routes
    GoRoute(
      path: '/hospital-search',
      builder: (context, state) => const SimpleHospitalSearchScreen(),
    ),
    GoRoute(
    path: '/doctor-search',
    builder: (context, state) => const SimpleDoctorSearchScreen(),
    ),
    GoRoute(
    path: '/ai-doctor',
    builder: (context, state) => const AIDoctorScreen(),
    ),
  ],
);