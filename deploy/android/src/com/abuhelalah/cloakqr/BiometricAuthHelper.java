package com.abuhelalah.cloakqr;

import android.app.KeyguardManager;
import android.content.Context;
import android.hardware.biometrics.BiometricManager;
import android.hardware.biometrics.BiometricPrompt;
import android.hardware.fingerprint.FingerprintManager;
import android.os.Build;
import android.os.CancellationSignal;
import android.util.Log;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Thin JNI bridge to the framework BiometricPrompt.
 *
 * The framework {@code android.hardware.biometrics.BiometricPrompt} only needs
 * a {@link Context} (unlike the androidx variant, which requires a
 * FragmentActivity), so it can be driven directly from QtActivity through JNI.
 * Results are reported back to C++ via the {@code onResult} native method.
 */
public final class BiometricAuthHelper {

    private static final String TAG = "CloakQRBiometric";

    private static final int STRONG_OR_WEAK =
            BiometricManager.Authenticators.BIOMETRIC_STRONG
                    | BiometricManager.Authenticators.BIOMETRIC_WEAK;

    // A single background thread delivers the callback; C++ then posts the
    // result back onto the Qt main thread.
    private static final Executor EXECUTOR = Executors.newSingleThreadExecutor();

    private static BiometricPrompt sPrompt;

    private BiometricAuthHelper() {
    }

    /** Called from C++ when authentication finishes; 0 = success. */
    public static native void onResult(int resultCode);

    /** True when the device is secured and has an enrolled fingerprint or face. */
    public static boolean isAvailable(Context context) {
        if (context == null) {
            return false;
        }
        KeyguardManager keyguard =
                (KeyguardManager) context.getSystemService(Context.KEYGUARD_SERVICE);
        if (keyguard == null || !keyguard.isDeviceSecure()) {
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            BiometricManager manager = context.getSystemService(BiometricManager.class);
            return manager != null
                    && manager.canAuthenticate(STRONG_OR_WEAK) == BiometricManager.BIOMETRIC_SUCCESS;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            BiometricManager manager = context.getSystemService(BiometricManager.class);
            return manager != null
                    && manager.canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS;
        }
        // API 28: no framework BiometricManager yet; fall back to fingerprints.
        FingerprintManager fingerprint =
                (FingerprintManager) context.getSystemService(Context.FINGERPRINT_SERVICE);
        return fingerprint != null
                && fingerprint.isHardwareDetected()
                && fingerprint.hasEnrolledFingerprints();
    }

    /** Shows the system biometric prompt. Non-blocking; result via onResult. */
    @SuppressWarnings("deprecation")
    public static void authenticate(Context context, String title, String subtitle,
                                    String description, String negativeText) {
        if (context == null) {
            return;
        }

        // Guarantees onResult is delivered exactly once: the negative button is
        // reported through the OnClickListener (the framework dismisses the
        // prompt without firing onAuthenticationError), while success and other
        // errors come through the AuthenticationCallback.
        final java.util.concurrent.atomic.AtomicBoolean finished =
                new java.util.concurrent.atomic.AtomicBoolean(false);

        BiometricPrompt.AuthenticationCallback callback =
                new BiometricPrompt.AuthenticationCallback() {
                    @Override
                    public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                        Log.i(TAG, "onAuthenticationSucceeded");
                        if (finished.compareAndSet(false, true)) {
                            onResult(0);
                        }
                    }

                    @Override
                    public void onAuthenticationFailed() {
                        Log.i(TAG, "onAuthenticationFailed");
                    }

                    @Override
                    public void onAuthenticationError(int errorCode, CharSequence errString) {
                        Log.i(TAG, "onAuthenticationError code=" + errorCode + " msg=" + errString);
                        if (finished.compareAndSet(false, true)) {
                            onResult(errorCode);
                        }
                    }
                };

        // Back button / swipe-away cancel the session through the framework;
        // the negative button is handled here because that path dismisses the
        // dialog without invoking onAuthenticationError.
        sPrompt = new BiometricPrompt.Builder(context)
                .setTitle(title)
                .setSubtitle(subtitle)
                .setDescription(description)
                .setNegativeButton(negativeText, EXECUTOR, (dialog, which) -> {
                    Log.i(TAG, "negativeButton");
                    if (finished.compareAndSet(false, true)) {
                        onResult(BiometricPrompt.BIOMETRIC_ERROR_USER_CANCELED);
                    }
                })
                .build();

        sPrompt.authenticate(new CancellationSignal(), EXECUTOR, callback);
    }
}
