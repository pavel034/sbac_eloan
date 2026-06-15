import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String uid;
  final String phone;
  final String? email;
  final String? fullName;
  final String? photoUrl;
  final String status;
  final String kycStatus;
  final bool isAdmin;
  final DateTime? createdAt;

  const AuthUser({
    required this.uid,
    required this.phone,
    this.email,
    this.fullName,
    this.photoUrl,
    this.status = 'active',
    this.kycStatus = 'pending',
    this.isAdmin = false,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String uid) {
    return AuthUser(
      uid: uid,
      phone: json['phone'] ?? '',
      email: json['email'],
      fullName: json['fullName'],
      photoUrl: json['photoUrl'],
      status: json['status'] ?? 'active',
      kycStatus: json['kycStatus'] ?? 'pending',
      isAdmin: json['isAdmin'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'email': email,
        'fullName': fullName,
        'photoUrl': photoUrl,
        'status': status,
        'kycStatus': kycStatus,
        'isAdmin': isAdmin,
        'createdAt': createdAt?.toIso8601String(),
      };

  AuthUser copyWith({
    String? fullName,
    String? email,
    String? photoUrl,
    String? kycStatus,
    String? status,
    bool? isAdmin,
  }) {
    return AuthUser(
      uid: uid,
      phone: phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
    );
  }
}

// Maps Firebase error codes to user-friendly messages
String _friendlyAuthError(Object e) {
  final msg = e.toString();
  if (msg.contains('network-request-failed') ||
      msg.contains('network_error') ||
      msg.contains('SocketException') ||
      msg.contains('TimeoutException')) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (msg.contains('user-not-found')) return 'No account found with this email.';
  if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
    return 'Incorrect email or password.';
  }
  if (msg.contains('email-already-in-use')) {
    return 'This email is already registered. Please log in instead.';
  }
  if (msg.contains('weak-password')) {
    return 'Password is too weak. Use at least 6 characters.';
  }
  if (msg.contains('invalid-email')) return 'Invalid email address format.';
  if (msg.contains('too-many-requests')) {
    return 'Too many attempts. Please wait a few minutes and try again.';
  }
  if (msg.contains('user-disabled')) {
    return 'This account has been disabled. Contact support.';
  }
  if (msg.contains('EMAIL_NOT_VERIFIED')) {
    return 'Please verify your email first. Check your inbox for a verification link.';
  }
  if (msg.contains('operation-not-allowed')) {
    return 'Email/Password login is not enabled. Contact administrator.';
  }
  return msg.replaceAll('Exception: ', '').replaceAll('[firebase_auth/', '').replaceAll(']', '');
}

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  // Web-only: ConfirmationResult cannot be serialized, so stored statically
  static ConfirmationResult? _webConfirmationResult;

  AuthenticationService(this._prefs);

  User? get currentUser => _firebaseAuth.currentUser;

  Future<AuthUser?> getCurrentUserData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Return a minimal user from Firebase Auth data
        return AuthUser(
          uid: user.uid,
          phone: user.phoneNumber ?? '',
          status: 'active',
          kycStatus: 'pending',
        );
      }
      return AuthUser.fromJson(doc.data()!, user.uid);
    } catch (e) {
      // Firestore blocked — return minimal user so app doesn't redirect to login
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return AuthUser(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        status: 'active',
        kycStatus: 'pending',
      );
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    if (kIsWeb) {
      // Web: Firebase auto-creates an invisible reCAPTCHA when no verifier is passed
      _webConfirmationResult =
          await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
    } else {
      // Mobile: use verifyPhoneNumber (stores verificationId in prefs)
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            throw Exception('Invalid phone number');
          }
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _prefs.setString('verificationId', verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _prefs.setString('verificationId', verificationId);
        },
      );
    }
  }

  Future<AuthUser> verifyOTPAndSignIn({
    required String phoneNumber,
    required String otp,
  }) async {
    UserCredential userCredential;

    if (kIsWeb) {
      if (_webConfirmationResult == null) {
        throw Exception('Session expired. Please request OTP again.');
      }
      userCredential = await _webConfirmationResult!.confirm(otp);
      _webConfirmationResult = null;
    } else {
      final verificationId = _prefs.getString('verificationId');
      if (verificationId == null) {
        throw Exception('Session expired. Please request OTP again.');
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      await _prefs.remove('verificationId');
    }

    final uid = userCredential.user!.uid;
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'phone': phoneNumber,
          'status': 'active',
          'kycStatus': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
          'loginCount': 1,
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
      } else {
        await _firestore.collection('users').doc(uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
          'loginCount': FieldValue.increment(1),
        });
      }
    } catch (_) {
      // Firestore write failed — still allow login with Auth data
    }

    return (await getCurrentUserData()) ??
        AuthUser(uid: uid, phone: phoneNumber, status: 'active', kycStatus: 'pending');
  }

  Future<AuthUser> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(fullName);
      await user.sendEmailVerification();
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'fullName': fullName,
          'phone': '',
          'status': 'active',
          'kycStatus': 'pending',
          'isAdmin': false,
          'createdAt': DateTime.now().toIso8601String(),
          'loginCount': 0,
        });
      } catch (_) {}
      // Sign out immediately — user must verify email before logging in
      await _firebaseAuth.signOut();
      return AuthUser(
        uid: user.uid,
        phone: '',
        email: email,
        fullName: fullName,
        status: 'active',
        kycStatus: 'pending',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      if (!user.emailVerified) {
        await _firebaseAuth.signOut();
        throw Exception('EMAIL_NOT_VERIFIED');
      }
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
          'loginCount': FieldValue.increment(1),
        });
      } catch (_) {}
      return (await getCurrentUserData()) ??
          AuthUser(
            uid: user.uid,
            phone: '',
            email: email,
            status: 'active',
            kycStatus: 'pending',
          );
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } catch (e) {
      if (e.toString().contains('EMAIL_NOT_VERIFIED')) rethrow;
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> sendEmailVerification() async {
    // Re-sign in required since we sign out after registration
    // Just send to the last known user if still available
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  Future<void> sendVerificationToEmail(String email, String password) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.sendEmailVerification();
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _prefs.clear();
    await _firebaseAuth.signOut();
  }

  Future<AuthUser> updateUserProfile({
    String? fullName,
    String? email,
    String? kycStatus,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (fullName != null) {
      updates['fullName'] = fullName;
      await user.updateDisplayName(fullName);
    }
    if (email != null) {
      updates['email'] = email;
    }
    if (kycStatus != null) {
      updates['kycStatus'] = kycStatus;
    }

    await _firestore.collection('users').doc(user.uid).update(updates);
    return (await getCurrentUserData())!;
  }

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();
}

// Providers

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) async => SharedPreferences.getInstance(),
);

final authServiceProvider =
    FutureProvider<AuthenticationService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthenticationService(prefs);
});

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final currentUserProvider = FutureProvider<AuthUser?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthenticationService(prefs).getCurrentUserData();
});

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthUser?>>(
  (ref) => AuthStateNotifier(ref),
);

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Handle current value immediately — ref.listen misses values already emitted
    _resolveAuthState(_ref.read(authStateProvider));

    // Then watch for future changes
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      _resolveAuthState(next);
    });
  }

  void _resolveAuthState(AsyncValue<User?> next) {
    if (!next.hasValue) return;
    if (next.value != null) {
      final firebaseUser = next.value!;
      // Email-auth users must verify their email before being treated as logged in
      if (firebaseUser.email != null && !firebaseUser.emailVerified) {
        state = const AsyncValue.data(null);
        return;
      }
      _ref.read(authServiceProvider.future).then((svc) async {
        if (mounted) state = AsyncValue.data(await svc.getCurrentUserData());
      });
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> sendOTP(String phone) async {
    // Do NOT change auth state here — user is still unauthenticated.
    // Changing state to loading would trigger the router to redirect to splash.
    final svc = await _ref.read(authServiceProvider.future);
    await svc.sendOTP(phone);
  }

  Future<void> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    final svc = await _ref.read(authServiceProvider.future);
    final user =
        await svc.verifyOTPAndSignIn(phoneNumber: phoneNumber, otp: otp);
    // Set state immediately so the router can redirect to home right away.
    // The authStateProvider stream will also fire shortly and confirm this.
    if (mounted) state = AsyncValue.data(user);
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // Do NOT set loading state — it redirects to splash and causes the login
    // page to "bounce". Handle loading in the UI widget instead.
    try {
      final svc = await _ref.read(authServiceProvider.future);
      final user = await svc.loginWithEmail(email: email, password: password);
      if (mounted) state = AsyncValue.data(user);
    } catch (e, st) {
      // Keep state as unauthenticated (not error) so the router stays on login
      if (mounted) state = const AsyncValue.data(null);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final svc = await _ref.read(authServiceProvider.future);
    await svc.registerWithEmail(
      fullName: fullName,
      email: email,
      password: password,
    );
    // Keep state as unauthenticated — user must verify email first
  }

  Future<void> resendVerificationEmail(String email, String password) async {
    final svc = await _ref.read(authServiceProvider.future);
    await svc.sendVerificationToEmail(email, password);
  }

  Future<void> resetPassword(String email) async {
    final svc = await _ref.read(authServiceProvider.future);
    await svc.resetPassword(email);
  }

  Future<void> logout() async {
    final svc = await _ref.read(authServiceProvider.future);
    await svc.logout();
    if (mounted) state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? kycStatus,
  }) async {
    // Do NOT set loading state — it redirects to splash and blocks navigation
    try {
      final svc = await _ref.read(authServiceProvider.future);
      final updated = await svc.updateUserProfile(
        fullName: fullName,
        email: email,
        kycStatus: kycStatus,
      );
      if (mounted) state = AsyncValue.data(updated);
    } catch (e, st) {
      // Keep current state on failure and rethrow so caller can show error
      Error.throwWithStackTrace(e, st);
    }
  }
}
