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
      if (!doc.exists) return null;
      return AuthUser.fromJson(doc.data()!, user.uid);
    } catch (e) {
      return null;
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

    return (await getCurrentUserData())!;
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
    if (!next.hasValue) return; // still loading or error — keep current state
    if (next.value != null) {
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

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final svc = await _ref.read(authServiceProvider.future);
      await svc.logout();
      return null;
    });
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? kycStatus,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final svc = await _ref.read(authServiceProvider.future);
      return svc.updateUserProfile(
        fullName: fullName,
        email: email,
        kycStatus: kycStatus,
      );
    });
  }
}
