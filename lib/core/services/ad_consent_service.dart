import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;

/// Handles production consent flows for Google Mobile Ads UMP.
class AdConsentService {
  AdConsentService({
    gma.ConsentInformation? consentInformation,
  }) : _consentInformation =
            consentInformation ?? gma.ConsentInformation.instance;

  final gma.ConsentInformation _consentInformation;

  Future<void>? _inFlightRefreshFuture;
  Future<void>? _inFlightGatherFuture;

  /// Requests the latest consent information from UMP.
  Future<void> refreshConsentInfo() async {
    if (kIsWeb) {
      return;
    }

    if (_inFlightRefreshFuture != null) {
      await _inFlightRefreshFuture;
      return;
    }

    final Future<void> refreshFuture = _refreshConsentInfoInternal();
    _inFlightRefreshFuture = refreshFuture;

    try {
      await refreshFuture;
    } finally {
      if (identical(_inFlightRefreshFuture, refreshFuture)) {
        _inFlightRefreshFuture = null;
      }
    }
  }

  /// Updates consent info and shows the UMP form if required.
  Future<void> gatherConsent() async {
    if (kIsWeb) {
      return;
    }

    if (_inFlightGatherFuture != null) {
      await _inFlightGatherFuture;
      return;
    }

    final Future<void> gatherFuture = _gatherConsentInternal();
    _inFlightGatherFuture = gatherFuture;

    try {
      await gatherFuture;
    } finally {
      if (identical(_inFlightGatherFuture, gatherFuture)) {
        _inFlightGatherFuture = null;
      }
    }
  }

  Future<void> _refreshConsentInfoInternal() async {
    final Completer<void> completer = Completer<void>();

    _consentInformation.requestConsentInfoUpdate(
      gma.ConsentRequestParameters(),
      () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (gma.FormError error) {
        debugPrint('Consent info update failed: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    await completer.future;
  }

  Future<void> _gatherConsentInternal() async {
    await refreshConsentInfo();

    try {
      await gma.ConsentForm.loadAndShowConsentFormIfRequired(
        (gma.FormError? error) {
          if (error != null) {
            debugPrint('Consent form dismissed with error: $error');
          }
        },
      );
    } catch (error) {
      debugPrint('Consent form load/show failed: $error');
    }
  }

  Future<bool> canRequestAds() async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await _consentInformation.canRequestAds();
    } catch (error) {
      debugPrint('Failed to check canRequestAds: $error');
      return false;
    }
  }

  Future<bool> isPrivacyOptionsRequired() async {
    if (kIsWeb) {
      return false;
    }

    await refreshConsentInfo();

    try {
      final gma.PrivacyOptionsRequirementStatus status =
          await _consentInformation.getPrivacyOptionsRequirementStatus();
      return status == gma.PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      debugPrint('Failed to read privacy options requirement status: $error');
      return false;
    }
  }

  Future<bool> showPrivacyOptionsForm() async {
    if (kIsWeb) {
      return false;
    }

    final Completer<bool> completer = Completer<bool>();

    try {
      await gma.ConsentForm.showPrivacyOptionsForm(
        (gma.FormError? error) {
          if (error != null) {
            debugPrint('Privacy options form dismissed with error: $error');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
            return;
          }

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );

      if (!completer.isCompleted) {
        completer.complete(true);
      }

      return await completer.future;
    } catch (error) {
      debugPrint('Failed to present privacy options form: $error');
      return false;
    }
  }
}
