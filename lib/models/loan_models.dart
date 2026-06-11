import 'package:flutter/material.dart';

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is String) return DateTime.parse(v);
  try { return (v as dynamic).toDate() as DateTime; } catch (_) { return DateTime.now(); }
}

DateTime? _parseDateNullable(dynamic v) {
  if (v == null) return null;
  return _parseDate(v);
}

// ============================================================================
// LOAN PRODUCT MODEL
// ============================================================================

class LoanProduct {
  final String productId;
  final String productName;
  final String productDescription;
  final double minAmount;
  final double maxAmount;
  final int minTenorMonths;
  final int maxTenorMonths;
  final double baseInterestRate;
  final bool isActive;
  final List<String> targetSegments;
  final List<String> documentRequirements;
  final DateTime createdAt;

  const LoanProduct({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.minAmount,
    required this.maxAmount,
    required this.minTenorMonths,
    required this.maxTenorMonths,
    required this.baseInterestRate,
    required this.isActive,
    required this.targetSegments,
    required this.documentRequirements,
    required this.createdAt,
  });

  factory LoanProduct.fromJson(Map<String, dynamic> json, String productId) {
    return LoanProduct(
      productId: productId,
      productName: json['productName'] ?? '',
      productDescription: json['productDescription'] ?? '',
      minAmount: (json['minAmount'] ?? 0).toDouble(),
      maxAmount: (json['maxAmount'] ?? 100000).toDouble(),
      minTenorMonths: json['minTenorMonths'] ?? 3,
      maxTenorMonths: json['maxTenorMonths'] ?? 12,
      baseInterestRate: (json['baseInterestRate'] ?? 12).toDouble(),
      isActive: json['isActive'] ?? true,
      targetSegments: List<String>.from(json['targetSegments'] ?? []),
      documentRequirements:
          List<String>.from(json['documentRequirements'] ?? []),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'productDescription': productDescription,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
        'minTenorMonths': minTenorMonths,
        'maxTenorMonths': maxTenorMonths,
        'baseInterestRate': baseInterestRate,
        'isActive': isActive,
        'targetSegments': targetSegments,
        'documentRequirements': documentRequirements,
        'createdAt': createdAt.toIso8601String(),
      };
}

// ============================================================================
// LOAN APPLICATION MODEL
// ============================================================================

enum LoanApplicationStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  disbursed,
  repaying,
  completed,
  defaulted,
  closed,
}

extension LoanApplicationStatusExt on LoanApplicationStatus {
  String get value {
    return toString().split('.').last.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst('_', '');
  }

  static LoanApplicationStatus fromString(String value) {
    return LoanApplicationStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => LoanApplicationStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case LoanApplicationStatus.draft:
        return 'Draft';
      case LoanApplicationStatus.submitted:
        return 'Submitted';
      case LoanApplicationStatus.underReview:
        return 'Under Review';
      case LoanApplicationStatus.approved:
        return 'Approved';
      case LoanApplicationStatus.rejected:
        return 'Rejected';
      case LoanApplicationStatus.disbursed:
        return 'Disbursed';
      case LoanApplicationStatus.repaying:
        return 'Repaying';
      case LoanApplicationStatus.completed:
        return 'Completed';
      case LoanApplicationStatus.defaulted:
        return 'Defaulted';
      case LoanApplicationStatus.closed:
        return 'Closed';
    }
  }

  Color get statusColor {
    switch (this) {
      case LoanApplicationStatus.draft:
        return Colors.grey;
      case LoanApplicationStatus.submitted:
        return Colors.blue;
      case LoanApplicationStatus.underReview:
        return Colors.orange;
      case LoanApplicationStatus.approved:
        return Colors.green;
      case LoanApplicationStatus.rejected:
        return Colors.red;
      case LoanApplicationStatus.disbursed:
        return Colors.purple;
      case LoanApplicationStatus.repaying:
        return Colors.indigo;
      case LoanApplicationStatus.completed:
        return Colors.teal;
      case LoanApplicationStatus.defaulted:
        return Colors.red;
      case LoanApplicationStatus.closed:
        return Colors.grey;
    }
  }
}

class LoanApplication {
  final String loanId;
  final String userId;
  final String productId;
  final double requestedAmount;
  final double? approvedAmount;
  final int loanTenureMonths;
  final int? approvedTenureMonths;
  final String loanPurpose;
  final String employmentType;
  final double monthlyIncome;
  final double existingDebts;
  final int existingLoans;
  final List<LoanDocument> documents;
  final String? applicantNotes;
  final String? internalNotes;
  final LoanApplicationStatus status;
  final String? rejectionReason;
  final bool consentGiven;
  final DateTime consentDate;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final DateTime? disbursedAt;
  final DateTime? expectedMaturityDate;
  // Credit risk assessment fields (filled by approver)
  final String? cibStatus;
  final double? dbr;
  final double? totalFundedOutstanding;
  final double? totalNonFundedOutstanding;
  final int? creditRiskScore;

  const LoanApplication({
    required this.loanId,
    required this.userId,
    required this.productId,
    required this.requestedAmount,
    this.approvedAmount,
    required this.loanTenureMonths,
    this.approvedTenureMonths,
    required this.loanPurpose,
    required this.employmentType,
    required this.monthlyIncome,
    required this.existingDebts,
    required this.existingLoans,
    required this.documents,
    this.applicantNotes,
    this.internalNotes,
    required this.status,
    this.rejectionReason,
    required this.consentGiven,
    required this.consentDate,
    required this.createdAt,
    this.submittedAt,
    this.decidedAt,
    this.disbursedAt,
    this.expectedMaturityDate,
    this.cibStatus,
    this.dbr,
    this.totalFundedOutstanding,
    this.totalNonFundedOutstanding,
    this.creditRiskScore,
  });

  factory LoanApplication.fromJson(
    Map<String, dynamic> json,
    String loanId,
  ) {
    return LoanApplication(
      loanId: loanId,
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      requestedAmount: (json['requestedAmount'] ?? 0).toDouble(),
      approvedAmount: json['approvedAmount'] != null
          ? (json['approvedAmount']).toDouble()
          : null,
      loanTenureMonths: json['loanTenureMonths'] ?? 12,
      approvedTenureMonths: json['approvedTenureMonths'],
      loanPurpose: json['loanPurpose'] ?? '',
      employmentType: json['employmentType'] ?? '',
      monthlyIncome: (json['monthlyIncome'] ?? 0).toDouble(),
      existingDebts: (json['existingDebts'] ?? 0).toDouble(),
      existingLoans: json['existingLoans'] ?? 0,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((doc) => LoanDocument.fromJson(doc))
              .toList() ??
          [],
      applicantNotes: json['applicantNotes'],
      internalNotes: json['internalNotes'],
      status:
          LoanApplicationStatusExt.fromString(json['status'] ?? 'draft'),
      rejectionReason: json['rejectionReason'],
      consentGiven: json['consentGiven'] ?? false,
      consentDate: _parseDate(json['consentDate']),
      createdAt: _parseDate(json['createdAt']),
      submittedAt: _parseDateNullable(json['submittedAt']),
      decidedAt: _parseDateNullable(json['decidedAt']),
      disbursedAt: _parseDateNullable(json['disbursedAt']),
      expectedMaturityDate: _parseDateNullable(json['expectedMaturityDate']),
      cibStatus: json['cibStatus'],
      dbr: json['dbr'] != null ? (json['dbr']).toDouble() : null,
      totalFundedOutstanding: json['totalFundedOutstanding'] != null
          ? (json['totalFundedOutstanding']).toDouble()
          : null,
      totalNonFundedOutstanding: json['totalNonFundedOutstanding'] != null
          ? (json['totalNonFundedOutstanding']).toDouble()
          : null,
      creditRiskScore: json['creditRiskScore'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'productId': productId,
        'requestedAmount': requestedAmount,
        'approvedAmount': approvedAmount,
        'loanTenureMonths': loanTenureMonths,
        'approvedTenureMonths': approvedTenureMonths,
        'loanPurpose': loanPurpose,
        'employmentType': employmentType,
        'monthlyIncome': monthlyIncome,
        'existingDebts': existingDebts,
        'existingLoans': existingLoans,
        'documents': documents.map((d) => d.toJson()).toList(),
        'applicantNotes': applicantNotes,
        'internalNotes': internalNotes,
        'status': status.value,
        'rejectionReason': rejectionReason,
        'consentGiven': consentGiven,
        'consentDate': consentDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'submittedAt': submittedAt?.toIso8601String(),
        'decidedAt': decidedAt?.toIso8601String(),
        'disbursedAt': disbursedAt?.toIso8601String(),
        'expectedMaturityDate': expectedMaturityDate?.toIso8601String(),
        'cibStatus': cibStatus,
        'dbr': dbr,
        'totalFundedOutstanding': totalFundedOutstanding,
        'totalNonFundedOutstanding': totalNonFundedOutstanding,
        'creditRiskScore': creditRiskScore,
      };
}

// ============================================================================
// LOAN DOCUMENT MODEL
// ============================================================================

class LoanDocument {
  final String documentId;
  final String documentType;
  final String fileUrl;
  final DateTime uploadedAt;
  final String verificationStatus;
  final String? verifiedBy;

  const LoanDocument({
    required this.documentId,
    required this.documentType,
    required this.fileUrl,
    required this.uploadedAt,
    required this.verificationStatus,
    this.verifiedBy,
  });

  factory LoanDocument.fromJson(Map<String, dynamic> json) {
    return LoanDocument(
      documentId: json['documentId'] ?? '',
      documentType: json['documentType'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      uploadedAt: _parseDate(json['uploadedAt']),
      verificationStatus: json['verificationStatus'] ?? 'pending',
      verifiedBy: json['verifiedBy'],
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'documentType': documentType,
        'fileUrl': fileUrl,
        'uploadedAt': uploadedAt.toIso8601String(),
        'verificationStatus': verificationStatus,
        'verifiedBy': verifiedBy,
      };
}

// ============================================================================
// CREDIT SCORE MODEL
// ============================================================================

enum RiskGrade { aPlus, a, b, c, reject }

extension RiskGradeExt on RiskGrade {
  String get displayName {
    switch (this) {
      case RiskGrade.aPlus:
        return 'A+';
      case RiskGrade.a:
        return 'A';
      case RiskGrade.b:
        return 'B';
      case RiskGrade.c:
        return 'C';
      case RiskGrade.reject:
        return 'Reject';
    }
  }

  Color get gradeColor {
    switch (this) {
      case RiskGrade.aPlus:
        return Colors.green;
      case RiskGrade.a:
        return Colors.lightGreen;
      case RiskGrade.b:
        return Colors.amber;
      case RiskGrade.c:
        return Colors.orange;
      case RiskGrade.reject:
        return Colors.red;
    }
  }
}

class CreditScore {
  final String scoreId;
  final String loanId;
  final int creditScore;
  final RiskGrade riskGrade;
  final double recommendedLoanLimit;
  final int recommendedTenureMonths;
  final double recommendedInterestRate;
  final String? scoreExplanation;
  final DateTime calculationTimestamp;

  const CreditScore({
    required this.scoreId,
    required this.loanId,
    required this.creditScore,
    required this.riskGrade,
    required this.recommendedLoanLimit,
    required this.recommendedTenureMonths,
    required this.recommendedInterestRate,
    this.scoreExplanation,
    required this.calculationTimestamp,
  });

  factory CreditScore.fromJson(Map<String, dynamic> json, String scoreId) {
    return CreditScore(
      scoreId: scoreId,
      loanId: json['loanId'] ?? '',
      creditScore: json['creditScore'] ?? 0,
      riskGrade: _parseRiskGrade(json['riskGrade']),
      recommendedLoanLimit: (json['recommendedLoanLimit'] ?? 0).toDouble(),
      recommendedTenureMonths: json['recommendedTenureMonths'] ?? 12,
      recommendedInterestRate:
          (json['recommendedInterestRate'] ?? 12).toDouble(),
      scoreExplanation: json['scoreExplanation'],
      calculationTimestamp: _parseDate(json['calculationTimestamp']),
    );
  }

  static RiskGrade _parseRiskGrade(String? value) {
    switch (value) {
      case 'A+':
        return RiskGrade.aPlus;
      case 'A':
        return RiskGrade.a;
      case 'B':
        return RiskGrade.b;
      case 'C':
        return RiskGrade.c;
      default:
        return RiskGrade.reject;
    }
  }
}

// ============================================================================
// REPAYMENT SCHEDULE MODEL
// ============================================================================

class RepaymentSchedule {
  final String repaymentId;
  final String loanId;
  final double principalAmount;
  final double interestRate;
  final int emiCount;
  final double emiAmount;
  final DateTime repaymentStartDate;
  final DateTime repaymentMaturityDate;
  final List<EMI> emiSchedule;
  final String status;

  const RepaymentSchedule({
    required this.repaymentId,
    required this.loanId,
    required this.principalAmount,
    required this.interestRate,
    required this.emiCount,
    required this.emiAmount,
    required this.repaymentStartDate,
    required this.repaymentMaturityDate,
    required this.emiSchedule,
    required this.status,
  });

  double get totalInterest => (emiAmount * emiCount) - principalAmount;
  double get totalRepayment => principalAmount + totalInterest;
  int get emisPaid =>
      emiSchedule.where((e) => e.status == 'paid').length;
  int get emisDue =>
      emiSchedule.where((e) => e.status == 'pending').length;

  factory RepaymentSchedule.fromJson(
    Map<String, dynamic> json,
    String repaymentId,
  ) {
    return RepaymentSchedule(
      repaymentId: repaymentId,
      loanId: json['loanId'] ?? '',
      principalAmount: (json['principalAmount'] ?? 0).toDouble(),
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      emiCount: json['emiCount'] ?? 0,
      emiAmount: (json['emiAmount'] ?? 0).toDouble(),
      repaymentStartDate: _parseDate(json['repaymentStartDate']),
      repaymentMaturityDate: _parseDate(json['repaymentMaturityDate']),
      emiSchedule: (json['emiSchedule'] as List<dynamic>?)
              ?.map((e) => EMI.fromJson(e))
              .toList() ??
          [],
      status: json['status'] ?? 'active',
    );
  }
}

// ============================================================================
// EMI MODEL
// ============================================================================

class EMI {
  final int emiNumber;
  final DateTime dueDate;
  final double principalComponent;
  final double interestComponent;
  final double totalAmount;
  final String status;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? transactionRefNo;

  const EMI({
    required this.emiNumber,
    required this.dueDate,
    required this.principalComponent,
    required this.interestComponent,
    required this.totalAmount,
    required this.status,
    this.paidDate,
    this.paymentMethod,
    this.transactionRefNo,
  });

  factory EMI.fromJson(Map<String, dynamic> json) {
    return EMI(
      emiNumber: json['emiNumber'] ?? 0,
      dueDate: _parseDate(json['dueDate']),
      principalComponent: (json['principalComponent'] ?? 0).toDouble(),
      interestComponent: (json['interestComponent'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paidDate: _parseDateNullable(json['paidDate']),
      paymentMethod: json['paymentMethod'],
      transactionRefNo: json['transactionRefNo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'emiNumber': emiNumber,
        'dueDate': dueDate.toIso8601String(),
        'principalComponent': principalComponent,
        'interestComponent': interestComponent,
        'totalAmount': totalAmount,
        'status': status,
        'paidDate': paidDate?.toIso8601String(),
        'paymentMethod': paymentMethod,
        'transactionRefNo': transactionRefNo,
      };
}
