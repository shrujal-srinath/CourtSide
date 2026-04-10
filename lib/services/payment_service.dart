// lib/services/payment_service.dart
//
// Bridges Razorpay's callback-based API into clean async/await.
// Android + iOS only — do NOT use on web.
//
// Security:
//   - Only RAZORPAY_KEY_ID (publishable key) is used here. The secret key
//     must never be in the client — it belongs in a server-side function only.
//   - Payment IDs are returned in PaymentSuccess and passed to BookingService;
//     they are never logged or stored elsewhere.

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// ── Result types ────────────────────────────────────────────────

sealed class PaymentResult {}

final class PaymentSuccess extends PaymentResult {
  PaymentSuccess({required this.paymentId});
  final String paymentId;
}

final class PaymentFailure extends PaymentResult {
  PaymentFailure({required this.message});
  final String message;
}

// ── Service ─────────────────────────────────────────────────────

class PaymentService {
  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  late final Razorpay _razorpay;
  Completer<PaymentResult>? _completer;

  /// Opens the native Razorpay payment sheet.
  ///
  /// [amountInPaise] MUST be in paise (rupees × 100).
  /// Resolves once Razorpay fires a success, error, or external-wallet event.
  Future<PaymentResult> initiatePayment({
    required int amountInPaise,
    required String description,
    required String userEmail,
    required String userName,
  }) {
    // Guard against concurrent payment attempts.
    if (_completer != null && !_completer!.isCompleted) {
      return Future.value(
        PaymentFailure(message: 'A payment is already in progress.'),
      );
    }

    _completer = Completer<PaymentResult>();

    final keyId = dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    if (keyId.isEmpty || keyId == 'rzp_test_XXXXXXXX') {
      _completer!.complete(
        PaymentFailure(message: 'Razorpay key not configured. Add your key to .env.'),
      );
      return _completer!.future;
    }

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amountInPaise, // Razorpay takes paise, NOT rupees
      'name': 'THE BOX',
      'description': description,
      'prefill': {
        'contact': '',
        'email': userEmail,
        'name': userName,
      },
      'theme': {'color': '#E8112D'},
      'send_sms_hash': true,
    };

    _razorpay.open(options);
    return _completer!.future;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_completer == null || _completer!.isCompleted) return;
    _completer!.complete(
      PaymentSuccess(paymentId: response.paymentId ?? ''),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_completer == null || _completer!.isCompleted) return;
    final message = response.message ?? 'Payment failed. Please try again.';
    _completer!.complete(PaymentFailure(message: message));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // The user selected an external wallet and the Razorpay sheet closed.
    // The Flutter future will not resolve from success/error events after this,
    // so we complete with a message asking the user to verify in their wallet.
    if (_completer == null || _completer!.isCompleted) return;
    _completer!.complete(
      PaymentFailure(
        message:
            '${response.walletName ?? 'Wallet'} payment selected. '
            'Please complete payment and retry booking if needed.',
      ),
    );
  }

  /// Must be called when the parent widget is disposed.
  void dispose() {
    _razorpay.clear();
  }
}
