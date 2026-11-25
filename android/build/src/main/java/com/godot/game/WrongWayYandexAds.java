package com.godot.game;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.yandex.mobile.ads.common.AdError;
import com.yandex.mobile.ads.common.AdRequest;
import com.yandex.mobile.ads.common.AdRequestError;
import com.yandex.mobile.ads.common.ImpressionData;
import com.yandex.mobile.ads.interstitial.InterstitialAd;
import com.yandex.mobile.ads.interstitial.InterstitialAdEventListener;
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadListener;
import com.yandex.mobile.ads.interstitial.InterstitialAdLoader;
import com.yandex.mobile.ads.rewarded.Reward;
import com.yandex.mobile.ads.rewarded.RewardedAd;
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener;
import com.yandex.mobile.ads.rewarded.RewardedAdLoadListener;
import com.yandex.mobile.ads.rewarded.RewardedAdLoader;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * WrongWayYandexAds - Native Yandex Mobile Ads SDK 8.7.0 bridge for Godot 4.7
 * Supports Interstitial and Rewarded Video ads on the Android UI thread.
 */
public class WrongWayYandexAds extends GodotPlugin {
    private static final String TAG = "WrongWayYandexAds";

    private static final SignalInfo SIG_INTERSTITIAL_LOADED = new SignalInfo("interstitial_loaded");
    private static final SignalInfo SIG_INTERSTITIAL_FAILED_LOAD = new SignalInfo("interstitial_failed_to_load", String.class);
    private static final SignalInfo SIG_INTERSTITIAL_DISMISSED = new SignalInfo("interstitial_dismissed");
    private static final SignalInfo SIG_INTERSTITIAL_FAILED_SHOW = new SignalInfo("interstitial_failed_to_show", String.class);

    private static final SignalInfo SIG_REWARDED_LOADED = new SignalInfo("rewarded_loaded");
    private static final SignalInfo SIG_REWARDED_FAILED_LOAD = new SignalInfo("rewarded_failed_to_load", String.class);
    private static final SignalInfo SIG_REWARDED_EARNED = new SignalInfo("rewarded_earned");
    private static final SignalInfo SIG_REWARDED_DISMISSED = new SignalInfo("rewarded_dismissed");
    private static final SignalInfo SIG_REWARDED_FAILED_SHOW = new SignalInfo("rewarded_failed_to_show", String.class);

    private InterstitialAdLoader interstitialAdLoader;
    private InterstitialAd interstitialAd;

    private RewardedAdLoader rewardedAdLoader;
    private RewardedAd rewardedAd;

    public WrongWayYandexAds(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "WrongWayYandexAds";
    }

    @NonNull
    @Override
    public List<String> getPluginMethods() {
        return Arrays.asList(
            "loadInterstitial",
            "isInterstitialReady",
            "showInterstitial",
            "loadRewarded",
            "isRewardedReady",
            "showRewarded"
        );
    }

    private static String safeMsg(String msg) {
        return (msg != null && !msg.isEmpty()) ? msg : "Unknown ad error";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(SIG_INTERSTITIAL_LOADED);
        signals.add(SIG_INTERSTITIAL_FAILED_LOAD);
        signals.add(SIG_INTERSTITIAL_DISMISSED);
        signals.add(SIG_INTERSTITIAL_FAILED_SHOW);
        signals.add(SIG_REWARDED_LOADED);
        signals.add(SIG_REWARDED_FAILED_LOAD);
        signals.add(SIG_REWARDED_EARNED);
        signals.add(SIG_REWARDED_DISMISSED);
        signals.add(SIG_REWARDED_FAILED_SHOW);
        return signals;
    }

    @UsedByGodot
    public void loadInterstitial(String adUnitId) {
        Activity activity = getActivity();
        if (activity == null || adUnitId == null || adUnitId.isEmpty()) {
            emitSignal(SIG_INTERSTITIAL_FAILED_LOAD.getName(), "Activity or adUnitId missing");
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                if (interstitialAdLoader == null) {
                    interstitialAdLoader = new InterstitialAdLoader(activity);
                }
                AdRequest request = new AdRequest.Builder(adUnitId).build();
                interstitialAdLoader.loadAd(request, new InterstitialAdLoadListener() {
                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd loadedAd) {
                        interstitialAd = loadedAd;
                        emitSignal(SIG_INTERSTITIAL_LOADED.getName());
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull AdRequestError error) {
                        interstitialAd = null;
                        Log.w(TAG, "Interstitial failed to load: " + error.getDescription());
                        emitSignal(SIG_INTERSTITIAL_FAILED_LOAD.getName(), safeMsg(error.getDescription()));
                    }
                });
            } catch (Exception e) {
                Log.e(TAG, "loadInterstitial exception: " + e.getMessage(), e);
                emitSignal(SIG_INTERSTITIAL_FAILED_LOAD.getName(), safeMsg(e.getMessage()));
            }
        });
    }

    @UsedByGodot
    public boolean isInterstitialReady() {
        return interstitialAd != null;
    }

    @UsedByGodot
    public void showInterstitial() {
        Activity activity = getActivity();
        if (activity == null) {
            emitSignal(SIG_INTERSTITIAL_FAILED_SHOW.getName(), "Activity null");
            return;
        }
        activity.runOnUiThread(() -> {
            if (interstitialAd == null) {
                emitSignal(SIG_INTERSTITIAL_FAILED_SHOW.getName(), "Interstitial not loaded");
                return;
            }
            InterstitialAd adToShow = interstitialAd;
            interstitialAd = null;
            adToShow.setAdEventListener(new InterstitialAdEventListener() {
                @Override
                public void onAdShown() {}

                @Override
                public void onAdFailedToShow(@NonNull AdError adError) {
                    adToShow.setAdEventListener(null);
                    emitSignal(SIG_INTERSTITIAL_FAILED_SHOW.getName(), safeMsg(adError.getDescription()));
                }

                @Override
                public void onAdDismissed() {
                    adToShow.setAdEventListener(null);
                    emitSignal(SIG_INTERSTITIAL_DISMISSED.getName());
                }

                @Override
                public void onAdClicked() {}

                @Override
                public void onAdImpression(@Nullable ImpressionData impressionData) {}
            });
            adToShow.show(activity);
        });
    }

    @UsedByGodot
    public void loadRewarded(String adUnitId) {
        Activity activity = getActivity();
        if (activity == null || adUnitId == null || adUnitId.isEmpty()) {
            emitSignal(SIG_REWARDED_FAILED_LOAD.getName(), "Activity or adUnitId missing");
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                if (rewardedAdLoader == null) {
                    rewardedAdLoader = new RewardedAdLoader(activity);
                }
                AdRequest request = new AdRequest.Builder(adUnitId).build();
                rewardedAdLoader.loadAd(request, new RewardedAdLoadListener() {
                    @Override
                    public void onAdLoaded(@NonNull RewardedAd loadedAd) {
                        rewardedAd = loadedAd;
                        emitSignal(SIG_REWARDED_LOADED.getName());
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull AdRequestError error) {
                        rewardedAd = null;
                        Log.w(TAG, "Rewarded failed to load: " + error.getDescription());
                        emitSignal(SIG_REWARDED_FAILED_LOAD.getName(), safeMsg(error.getDescription()));
                    }
                });
            } catch (Exception e) {
                Log.e(TAG, "loadRewarded exception: " + e.getMessage(), e);
                emitSignal(SIG_REWARDED_FAILED_LOAD.getName(), safeMsg(e.getMessage()));
            }
        });
    }

    @UsedByGodot
    public boolean isRewardedReady() {
        return rewardedAd != null;
    }

    @UsedByGodot
    public void showRewarded() {
        Activity activity = getActivity();
        if (activity == null) {
            emitSignal(SIG_REWARDED_FAILED_SHOW.getName(), "Activity null");
            return;
        }
        activity.runOnUiThread(() -> {
            if (rewardedAd == null) {
                emitSignal(SIG_REWARDED_FAILED_SHOW.getName(), "Rewarded not loaded");
                return;
            }
            RewardedAd adToShow = rewardedAd;
            rewardedAd = null;
            adToShow.setAdEventListener(new RewardedAdEventListener() {
                @Override
                public void onAdShown() {}

                @Override
                public void onAdFailedToShow(@NonNull AdError adError) {
                    adToShow.setAdEventListener(null);
                    emitSignal(SIG_REWARDED_FAILED_SHOW.getName(), safeMsg(adError.getDescription()));
                }

                @Override
                public void onAdDismissed() {
                    adToShow.setAdEventListener(null);
                    emitSignal(SIG_REWARDED_DISMISSED.getName());
                }

                @Override
                public void onAdClicked() {}

                @Override
                public void onAdImpression(@Nullable ImpressionData impressionData) {}

                @Override
                public void onRewarded(@NonNull Reward reward) {
                    emitSignal(SIG_REWARDED_EARNED.getName());
                }
            });
            adToShow.show(activity);
        });
    }

    @Override
    public void onMainDestroy() {
        if (interstitialAd != null) {
            interstitialAd.setAdEventListener(null);
            interstitialAd = null;
        }
        if (rewardedAd != null) {
            rewardedAd.setAdEventListener(null);
            rewardedAd = null;
        }
        if (interstitialAdLoader != null) {
            interstitialAdLoader.cancelLoading();
            interstitialAdLoader = null;
        }
        if (rewardedAdLoader != null) {
            rewardedAdLoader.cancelLoading();
            rewardedAdLoader = null;
        }
    }
}
