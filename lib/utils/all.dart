// ignore_for_file: avoid_print

class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => message;
}

class AppConstants {
  static const String appName = 'SBAC E-Loan';
  static const double minLoanAmount = 10000;
  static const double maxLoanAmount = 100000;
  static const int minLoanTenure = 3;
  static const int maxLoanTenure = 12;
  static const int otpExpiry = 300;
}

class Validators {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^(?:\+880|0)1[3-9]\d{8}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid Bangladesh phone number';
    }
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'OTP must be numbers only';
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) return 'Enter a valid amount';
    if (amount < AppConstants.minLoanAmount) {
      return 'Minimum amount is BDT ${AppConstants.minLoanAmount.toStringAsFixed(0)}';
    }
    if (amount > AppConstants.maxLoanAmount) {
      return 'Maximum amount is BDT ${AppConstants.maxLoanAmount.toStringAsFixed(0)}';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validateNID(String? value) {
    if (value == null || value.isEmpty) return 'NID is required';
    if (value.length != 10 && value.length != 13 && value.length != 17) {
      return 'NID must be 10, 13, or 17 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'NID must be numbers only';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateIncome(String? value) {
    if (value == null || value.isEmpty) return 'Monthly income is required';
    final income = double.tryParse(value.replaceAll(',', ''));
    if (income == null || income <= 0) return 'Enter a valid income amount';
    return null;
  }
}

class Formatters {
  static String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m.group(1)},',
    );
    return 'BDT $formatted';
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('880')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+880${cleaned.substring(1)}';
    return cleaned;
  }
}

extension StringExtension on String {
  bool get isValidPhone {
    return RegExp(r'^(?:\+880|0)1[3-9]\d{8}$').hasMatch(this);
  }

  String get toTitleCase {
    return split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

extension DateTimeExtension on DateTime {
  String get formattedDate => Formatters.formatDate(this);
}

extension DoubleExtension on double {
  String get asCurrency => Formatters.formatCurrency(this);
}
