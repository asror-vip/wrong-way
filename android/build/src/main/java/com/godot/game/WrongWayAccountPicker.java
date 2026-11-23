package com.godot.game;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * WrongWayAccountPicker - Native Android Google Account Chooser
 * Pops up Android OS native system account selection sheet directly in the game.
 */
public class WrongWayAccountPicker extends GodotPlugin {
    private static final String TAG = "WrongWayAccountPicker";
    public static final int RC_CHOOSE_ACCOUNT = 8943;

    private static final SignalInfo SIGNAL_ACCOUNT_PICKED = new SignalInfo("account_picked", String.class, String.class);
    private static final SignalInfo SIGNAL_ACCOUNT_PICKER_FAILED = new SignalInfo("account_picker_failed", String.class);

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
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(SIGNAL_ACCOUNT_PICKED);
        signals.add(SIGNAL_ACCOUNT_PICKER_FAILED);
        return signals;
    }

    @UsedByGodot
    public void openAccountPicker() {
        Activity activity = getActivity();
        if (activity == null) {
            emitSignal(SIGNAL_ACCOUNT_PICKER_FAILED.getName(), "Activity not available");
            return;
        }

        activity.runOnUiThread(() -> {
            try {
                Intent intent;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    intent = AccountManager.newChooseAccountIntent(
                        null,
                        null,
                        new String[]{"com.google"},
                        null,
                        null,
                        null,
                        null
                    );
                } else {
                    intent = AccountManager.newChooseAccountIntent(
                        null,
                        null,
                        new String[]{"com.google"},
                        false,
                        null,
                        null,
                        null,
                        null
                    );
                }
                activity.startActivityForResult(intent, RC_CHOOSE_ACCOUNT);
            } catch (Exception e) {
                Log.e(TAG, "Error opening account picker: " + e.getMessage(), e);
                emitSignal(SIGNAL_ACCOUNT_PICKER_FAILED.getName(), e.getMessage());
            }
        });
    }

    @Override
    public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == RC_CHOOSE_ACCOUNT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                String accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME);
                if (accountName != null && !accountName.isEmpty()) {
                    String displayName = accountName.split("@")[0];
                    if (!displayName.isEmpty()) {
                        displayName = Character.toUpperCase(displayName.charAt(0)) + displayName.substring(1);
                    }
                    emitSignal(SIGNAL_ACCOUNT_PICKED.getName(), accountName, displayName);
                    return;
                }
            }
            emitSignal(SIGNAL_ACCOUNT_PICKER_FAILED.getName(), "Bekor qilindi");
        }
    }
}
