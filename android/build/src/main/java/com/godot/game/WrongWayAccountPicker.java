package com.godot.game;

import android.app.Activity;
import android.os.CancellationSignal;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialCancellationException;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.exceptions.GetCredentialProviderConfigurationException;
import androidx.credentials.exceptions.NoCredentialException;

import com.google.android.libraries.identity.googleid.GetGoogleIdOption;
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * WrongWayAccountPicker - Hardened Native Android Google Sign-In Modal
 * Primary: GetSignInWithGoogleOption (explicit button modal dialog, immune to One-Tap cooldown).
 * Automatic Fallback: GetGoogleIdOption (bottom sheet chooser for older Play Services).
 * Never opens a browser; guarantees non-null Strings on every Godot signal emission.
 */
public class WrongWayAccountPicker extends GodotPlugin {
    private static final String TAG = "WrongWayAccountPicker";

    private static final SignalInfo SIG_SUCCESS = new SignalInfo(
        "google_sign_in_success", String.class, String.class, String.class
    );
    private static final SignalInfo SIG_FAILED = new SignalInfo(
        "google_sign_in_failed", String.class, String.class
    );

    private CancellationSignal activeCancellationSignal;

    public WrongWayAccountPicker(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "WrongWayAccountPicker";
    }

    @NonNull
    @Override
    public List<String> getPluginMethods() {
        return Arrays.asList("signInWithGoogle");
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(SIG_SUCCESS);
        signals.add(SIG_FAILED);
        return signals;
    }

    private void safeEmitFailed(String code, String msg) {
        String safeCode = (code != null && !code.isEmpty()) ? code : "ERROR";
        String safeMsg = (msg != null && !msg.isEmpty()) ? msg : "Noma'lum xatolik";
        emitSignal(SIG_FAILED.getName(), safeCode, safeMsg);
    }

    @UsedByGodot
    public void signInWithGoogle(String webClientId) {
        Activity activity = getActivity();
        if (activity == null || activity.isFinishing() || activity.isDestroyed()) {
            safeEmitFailed("NO_ACTIVITY", "Activity mavjud emas");
            return;
        }
        final String clientId = webClientId != null ? webClientId.trim() : "";
        if (clientId.isEmpty()) {
            safeEmitFailed("NO_CLIENT_ID", "Google Web Client ID sozlanmagan");
            return;
        }

        activity.runOnUiThread(() -> {
            if (activeCancellationSignal != null) {
                try {
                    activeCancellationSignal.cancel();
                } catch (Exception ignored) {}
                activeCancellationSignal = null;
            }
            requestSignInModal(activity, clientId, true);
        });
    }

    private void requestSignInModal(
        @NonNull Activity activity,
        @NonNull String clientId,
        boolean allowFallbackToBottomSheet
    ) {
        if (activity.isFinishing() || activity.isDestroyed()) {
            safeEmitFailed("NO_ACTIVITY", "Activity mavjud emas");
            return;
        }
        try {
            CredentialManager credentialManager = CredentialManager.create(activity);
            GetCredentialRequest.Builder reqBuilder = new GetCredentialRequest.Builder();

            if (allowFallbackToBottomSheet) {
                GetSignInWithGoogleOption signInOption = new GetSignInWithGoogleOption.Builder(clientId)
                    .build();
                reqBuilder.addCredentialOption(signInOption);
            } else {
                GetGoogleIdOption googleIdOption = new GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(clientId)
                    .setAutoSelectEnabled(false)
                    .build();
                reqBuilder.addCredentialOption(googleIdOption);
            }

            final CancellationSignal signal = new CancellationSignal();
            activeCancellationSignal = signal;

            credentialManager.getCredentialAsync(
                activity,
                reqBuilder.build(),
                signal,
                ContextCompat.getMainExecutor(activity),
                new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                    @Override
                    public void onResult(@NonNull GetCredentialResponse result) {
                        if (activeCancellationSignal == signal) {
                            activeCancellationSignal = null;
                        }
                        handleCredentialResponse(result);
                    }

                    @Override
                    public void onError(@NonNull GetCredentialException e) {
                        if (activeCancellationSignal == signal) {
                            activeCancellationSignal = null;
                        }
                        Log.w(TAG, "Google Sign-In error (" + (allowFallbackToBottomSheet ? "modal" : "sheet") + "): "
                            + e.getClass().getSimpleName() + " - " + e.getMessage());

                        if (e instanceof GetCredentialCancellationException) {
                            if (!signal.isCanceled()) {
                                safeEmitFailed("CANCELED", "Kirish bekor qilindi");
                            }
                            return;
                        }

                        if (allowFallbackToBottomSheet) {
                            requestSignInModal(activity, clientId, false);
                            return;
                        }

                        if (e instanceof GetCredentialProviderConfigurationException) {
                            safeEmitFailed("PROVIDER_MISSING", "Google Play Services talab qilinadi yoki yangilanishi kerak");
                        } else if (e instanceof NoCredentialException) {
                            safeEmitFailed("NO_CREDENTIAL", "Telefonda Google hisobi topilmadi (Sozlamalardan Google qo'shing)");
                        } else {
                            String raw = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
                            safeEmitFailed("ERROR", raw);
                        }
                    }
                }
            );
        } catch (Exception e) {
            Log.e(TAG, "requestSignInModal exception: " + e.getMessage(), e);
            if (allowFallbackToBottomSheet) {
                requestSignInModal(activity, clientId, false);
            } else {
                safeEmitFailed("EXCEPTION", String.valueOf(e.getMessage()));
            }
        }
    }

    private void handleCredentialResponse(@NonNull GetCredentialResponse result) {
        Credential credential = result.getCredential();
        if (credential instanceof CustomCredential) {
            CustomCredential custom = (CustomCredential) credential;
            if (GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL.equals(custom.getType())) {
                try {
                    GoogleIdTokenCredential googleCred = GoogleIdTokenCredential.createFrom(custom.getData());
                    String email = googleCred.getId() != null ? googleCred.getId() : "";
                    String displayName = googleCred.getDisplayName() != null ? googleCred.getDisplayName() : "";
                    String idToken = googleCred.getIdToken() != null ? googleCred.getIdToken() : "";
                    if (email.isEmpty()) {
                        safeEmitFailed("EMPTY_EMAIL", "Google hisobidan email olinmadi");
                        return;
                    }
                    Log.i(TAG, "Google Sign-In succeeded: " + email);
                    emitSignal(SIG_SUCCESS.getName(), email, displayName, idToken);
                    return;
                } catch (Exception e) {
                    Log.e(TAG, "Failed to parse GoogleIdTokenCredential", e);
                    safeEmitFailed("PARSE_ERROR", String.valueOf(e.getMessage()));
                    return;
                }
            }
        }
        safeEmitFailed("UNEXPECTED_CREDENTIAL", "Noto'g'ri Google javobi olindi");
    }
}
