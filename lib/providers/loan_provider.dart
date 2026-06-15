import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/loan_models.dart';
import '../providers/auth_provider.dart';

class LoanSummary {
  final int totalApplications;
  final int activeLoans;
  final int pendingApplications;
  final double totalApproved;

  const LoanSummary({
    required this.totalApplications,
    required this.activeLoans,
    required this.pendingApplications,
    required this.totalApproved,
  });
}

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LoanProduct>> getLoanProducts() async {
    try {
      final snapshot = await _firestore
          .collection('loan_products')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => LoanProduct.fromJson(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<LoanProduct?> getLoanProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection('loan_products')
          .doc(productId)
          .get();
      if (!doc.exists) return null;
      return LoanProduct.fromJson(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<LoanApplication> submitLoanApplication({
    required String userId,
    required String productId,
    required double requestedAmount,
    required int loanTenureMonths,
    required String loanPurpose,
    required String employmentType,
    required double monthlyIncome,
    required double existingDebts,
    required int existingLoans,
    required List<LoanDocument> documents,
    String? applicantNotes,
    required bool consentGiven,
  }) async {
    final loanId =
        _firestore.collection('loan_applications').doc().id;
    final now = DateTime.now();

    final application = LoanApplication(
      loanId: loanId,
      userId: userId,
      productId: productId,
      requestedAmount: requestedAmount,
      loanTenureMonths: loanTenureMonths,
      loanPurpose: loanPurpose,
      employmentType: employmentType,
      monthlyIncome: monthlyIncome,
      existingDebts: existingDebts,
      existingLoans: existingLoans,
      documents: documents,
      applicantNotes: applicantNotes,
      status: LoanApplicationStatus.submitted,
      consentGiven: consentGiven,
      consentDate: now,
      createdAt: now,
      submittedAt: now,
    );

    await _firestore
        .collection('loan_applications')
        .doc(loanId)
        .set(application.toJson());
    return application;
  }

  Future<List<LoanApplication>> getUserLoans(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('loan_applications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => LoanApplication.fromJson(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<LoanApplication?> getLoanDetails(String loanId) async {
    try {
      final doc = await _firestore
          .collection('loan_applications')
          .doc(loanId)
          .get();
      if (!doc.exists) return null;
      return LoanApplication.fromJson(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<RepaymentSchedule?> getRepaymentSchedule(String loanId) async {
    try {
      final doc =
          await _firestore.collection('repayments').doc(loanId).get();
      if (!doc.exists) return null;
      return RepaymentSchedule.fromJson(doc.data()!, loanId);
    } catch (_) {
      return null;
    }
  }

  Future<LoanSummary> getUserLoanSummary(String userId) async {
    try {
      final loans = await getUserLoans(userId);
      return LoanSummary(
        totalApplications: loans.length,
        activeLoans: loans
            .where((l) =>
                l.status == LoanApplicationStatus.disbursed ||
                l.status == LoanApplicationStatus.repaying)
            .length,
        pendingApplications: loans
            .where((l) =>
                l.status == LoanApplicationStatus.submitted ||
                l.status == LoanApplicationStatus.underReview)
            .length,
        totalApproved: loans
            .where((l) => l.approvedAmount != null)
            .fold(0.0, (acc, l) => acc + (l.approvedAmount ?? 0)),
      );
    } catch (_) {
      return const LoanSummary(
          totalApplications: 0,
          activeLoans: 0,
          pendingApplications: 0,
          totalApproved: 0);
    }
  }

  Future<List<LoanApplication>> getPendingApplications() async {
    try {
      final snapshot = await _firestore
          .collection('loan_applications')
          .where('status', whereIn: ['submitted', 'under_review'])
          .get();
      final results = snapshot.docs
          .map((doc) => LoanApplication.fromJson(doc.data(), doc.id))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<List<LoanApplication>> getAllApplications() async {
    try {
      final snapshot = await _firestore
          .collection('loan_applications')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => LoanApplication.fromJson(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> approveLoan(
    String loanId, {
    required double approvedAmount,
    required int approvedTenureMonths,
    String? internalNotes,
    required String cibStatus,
    required double dbr,
    required double totalFundedOutstanding,
    required double totalNonFundedOutstanding,
    required int creditRiskScore,
  }) async {
    await _firestore.collection('loan_applications').doc(loanId).update({
      'status': 'approved',
      'approvedAmount': approvedAmount,
      'approvedTenureMonths': approvedTenureMonths,
      if (internalNotes != null && internalNotes.isNotEmpty)
        'internalNotes': internalNotes,
      'cibStatus': cibStatus,
      'dbr': dbr,
      'totalFundedOutstanding': totalFundedOutstanding,
      'totalNonFundedOutstanding': totalNonFundedOutstanding,
      'creditRiskScore': creditRiskScore,
      'decidedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> rejectLoan(
    String loanId, {
    required String rejectionReason,
    String? cibStatus,
    double? dbr,
    double? totalFundedOutstanding,
    double? totalNonFundedOutstanding,
    int? creditRiskScore,
  }) async {
    await _firestore.collection('loan_applications').doc(loanId).update({
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'cibStatus': ?cibStatus,
      'dbr': ?dbr,
      'totalFundedOutstanding': ?totalFundedOutstanding,
      'totalNonFundedOutstanding': ?totalNonFundedOutstanding,
      'creditRiskScore': ?creditRiskScore,
      'decidedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markUnderReview(String loanId) async {
    await _firestore.collection('loan_applications').doc(loanId).update({
      'status': 'under_review',
    });
  }

  Future<CreditScore?> getCreditScore(String loanId) async {
    final snapshot = await _firestore
        .collection('ai_scores')
        .where('loanId', isEqualTo: loanId)
        .orderBy('calculationTimestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return CreditScore.fromJson(doc.data(), doc.id);
  }
}

// Providers

final loanServiceProvider = Provider<LoanService>((_) => LoanService());

final loanProductsProvider = FutureProvider<List<LoanProduct>>((ref) {
  return ref.watch(loanServiceProvider).getLoanProducts();
});

final loanProductProvider =
    FutureProvider.family<LoanProduct?, String>((ref, productId) {
  return ref.watch(loanServiceProvider).getLoanProduct(productId);
});

final userLoansProvider =
    FutureProvider<List<LoanApplication>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return ref.watch(loanServiceProvider).getUserLoans(user.uid);
});

final loanDetailsProvider =
    FutureProvider.family<LoanApplication?, String>((ref, loanId) {
  return ref.watch(loanServiceProvider).getLoanDetails(loanId);
});

final repaymentScheduleProvider =
    FutureProvider.family<RepaymentSchedule?, String>((ref, loanId) {
  return ref.watch(loanServiceProvider).getRepaymentSchedule(loanId);
});

final creditScoreProvider =
    FutureProvider.family<CreditScore?, String>((ref, loanId) {
  return ref.watch(loanServiceProvider).getCreditScore(loanId);
});

final loanSummaryProvider = FutureProvider<LoanSummary?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return ref.read(loanServiceProvider).getUserLoanSummary(user.uid);
});

final pendingApplicationsProvider =
    FutureProvider<List<LoanApplication>>((ref) {
  return ref.read(loanServiceProvider).getPendingApplications();
});

final allApplicationsProvider =
    FutureProvider<List<LoanApplication>>((ref) {
  return ref.read(loanServiceProvider).getAllApplications();
});

// Loan application form state

class LoanFormState {
  final String? productId;
  final double amount;
  final int tenureMonths;
  final String? loanPurpose;
  final String? employmentType;
  final double monthlyIncome;
  final double existingDebts;
  final int existingLoans;
  final String? applicantNotes;
  final bool consentGiven;
  final List<LoanDocument> documents;

  const LoanFormState({
    this.productId,
    this.amount = 10000,
    this.tenureMonths = 6,
    this.loanPurpose,
    this.employmentType,
    this.monthlyIncome = 0,
    this.existingDebts = 0,
    this.existingLoans = 0,
    this.applicantNotes,
    this.consentGiven = false,
    this.documents = const [],
  });

  bool get isStep1Complete =>
      amount >= 10000 && amount <= 100000 && tenureMonths >= 3;

  bool get isStep2Complete =>
      loanPurpose != null &&
      employmentType != null &&
      monthlyIncome > 0;

  bool get isReadyToSubmit => isStep1Complete && isStep2Complete && consentGiven;

  LoanFormState copyWith({
    String? productId,
    double? amount,
    int? tenureMonths,
    String? loanPurpose,
    String? employmentType,
    double? monthlyIncome,
    double? existingDebts,
    int? existingLoans,
    String? applicantNotes,
    bool? consentGiven,
    List<LoanDocument>? documents,
  }) {
    return LoanFormState(
      productId: productId ?? this.productId,
      amount: amount ?? this.amount,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      loanPurpose: loanPurpose ?? this.loanPurpose,
      employmentType: employmentType ?? this.employmentType,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      existingDebts: existingDebts ?? this.existingDebts,
      existingLoans: existingLoans ?? this.existingLoans,
      applicantNotes: applicantNotes ?? this.applicantNotes,
      consentGiven: consentGiven ?? this.consentGiven,
      documents: documents ?? this.documents,
    );
  }
}

final loanFormProvider =
    StateNotifierProvider<LoanFormNotifier, LoanFormState>(
  (_) => LoanFormNotifier(),
);

class LoanFormNotifier extends StateNotifier<LoanFormState> {
  LoanFormNotifier() : super(const LoanFormState());

  void setAmount(double v) => state = state.copyWith(amount: v);
  void setTenure(int v) => state = state.copyWith(tenureMonths: v);
  void setLoanPurpose(String v) => state = state.copyWith(loanPurpose: v);
  void setEmploymentType(String v) =>
      state = state.copyWith(employmentType: v);
  void setMonthlyIncome(double v) =>
      state = state.copyWith(monthlyIncome: v);
  void setExistingDebts(double v) =>
      state = state.copyWith(existingDebts: v);
  void setExistingLoans(int v) =>
      state = state.copyWith(existingLoans: v);
  void setNotes(String v) => state = state.copyWith(applicantNotes: v);
  void setConsent(bool v) => state = state.copyWith(consentGiven: v);
  void addDocument(LoanDocument d) =>
      state = state.copyWith(documents: [...state.documents, d]);
  void removeDocument(String id) => state = state.copyWith(
        documents: state.documents.where((d) => d.documentId != id).toList(),
      );
  void reset() => state = const LoanFormState();
}
