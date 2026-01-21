package com.testpilot.watcher;

import androidx.test.uiautomator.UiDevice;
import androidx.test.uiautomator.UiObject2;
import androidx.test.uiautomator.By;
import androidx.test.uiautomator.Until;
import android.util.Log;
import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

/**
 * Native Dialog Watcher for Flutter Test Pilot
 * Monitors and automatically handles native Android dialogs during test
 * execution
 * NOW WITH TEST-DRIVEN CONFIGURATION!
 */
public class NativeWatcher {
    private static final String TAG = "TestPilotWatcher";
    private static final long POLL_INTERVAL_MS = 200;
    private static final long STABILIZE_DELAY_MS = 500;
    private static final String CONFIG_PATH = "/sdcard/flutter_test_pilot_watcher_config.json";

    private UiDevice device;
    private int dialogsDetected = 0;
    private int dialogsDismissed = 0;
    private WatcherConfiguration config;
    private long lastConfigCheck = 0;
    private static final long CONFIG_CHECK_INTERVAL = 5000; // Check config every 5 seconds

    @Test
    public void testWatchForDialogs() throws Exception {
        device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());

        Log.d(TAG, "🤖 Native watcher started (TEST-DRIVEN MODE)");
        Log.d(TAG, "Device: " + device.getProductName());
        Log.d(TAG, "Android version: " + android.os.Build.VERSION.RELEASE);

        // Load initial configuration
        loadConfiguration();

        // Run watcher loop indefinitely
        while (true) {
            try {
                // Periodically reload configuration
                long now = System.currentTimeMillis();
                if (now - lastConfigCheck > CONFIG_CHECK_INTERVAL) {
                    loadConfiguration();
                    lastConfigCheck = now;
                }

                // Check for various dialog types based on configuration
                handleGoogleCredentialPicker();
                handlePermissionDialogs();
                handleLocationPermission();
                handleNotificationPermission();
                handleSystemAlerts();
                handleAppNotRespondingDialog();

                // Poll interval
                Thread.sleep(POLL_INTERVAL_MS);
            } catch (InterruptedException e) {
                Log.e(TAG, "Watcher interrupted", e);
                break;
            } catch (Exception e) {
                Log.e(TAG, "Error in watcher loop: " + e.getMessage(), e);
                // Continue watching despite errors
            }
        }

        Log.d(TAG, "🛑 Watcher stopped. Stats: detected=" + dialogsDetected + ", dismissed=" + dialogsDismissed);
    }

    /**
     * Load configuration from device storage
     */
    private void loadConfiguration() {
        try {
            File configFile = new File(CONFIG_PATH);
            if (configFile.exists()) {
                BufferedReader reader = new BufferedReader(new FileReader(configFile));
                StringBuilder jsonBuilder = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    jsonBuilder.append(line);
                }
                reader.close();

                JSONObject json = new JSONObject(jsonBuilder.toString());
                config = new WatcherConfiguration(json);

                Log.d(TAG, "📝 Configuration loaded from test:");
                Log.d(TAG, "   Permissions: " + config.permissionAction);
                Log.d(TAG, "   Location: " + config.locationPrecision);
                Log.d(TAG, "   Notifications: " + config.notificationAction);
                Log.d(TAG, "   System Dialogs: " + config.systemDialogAction);
            } else {
                // Use default configuration
                config = WatcherConfiguration.getDefault();
                Log.d(TAG, "ℹ️  No test configuration found, using defaults (allow all)");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error loading configuration: " + e.getMessage());
            config = WatcherConfiguration.getDefault();
        }
    }

    /**
     * Handle Google Credential Picker dialog
     */
    private void handleGoogleCredentialPicker() throws InterruptedException {
        if (!config.shouldHandleGooglePicker()) {
            return; // Test says ignore
        }

        UiObject2 picker = device.findObject(
                By.res("com.google.android.gms:id/credential_picker"));

        if (picker != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Google Credential Picker");
            Log.d(TAG, "   Action from test: " + config.googlePickerAction);

            device.pressBack();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Dismissed via back button (as per test config)");
        }
    }

    /**
     * Handle generic permission dialogs
     */
    private void handlePermissionDialogs() throws InterruptedException {
        if (config.permissionAction.equals("ignore")) {
            return; // Test says don't handle permissions
        }

        // Try multiple button text variations for different Android versions
        String[] allowTexts = {
                "While using the app", // Android 11+
                "Only this time", // Android 11+
                "Allow", // Android 10 and below
                "Allow only while using the app",
                "WHILE USING THE APP", // Some devices use uppercase
                "ALLOW"
        };

        for (String allowText : allowTexts) {
            UiObject2 allowButton = device.findObject(By.text(allowText));

            if (allowButton != null) {
                dialogsDetected++;
                Log.d(TAG, "🚨 Detected: Permission Dialog (button: '" + allowText + "')");
                Log.d(TAG, "   Test directive: " + config.permissionAction);

                if (config.permissionAction.equals("allow")) {
                    allowButton.click();
                    Thread.sleep(STABILIZE_DELAY_MS);
                    dialogsDismissed++;
                    Log.d(TAG, "✅ Granted permission (clicked '" + allowText + "')");
                } else if (config.permissionAction.equals("deny")) {
                    // Look for deny button
                    UiObject2 denyButton = device.findObject(By.text("Don't allow"));
                    if (denyButton == null) {
                        denyButton = device.findObject(By.text("Deny"));
                    }
                    if (denyButton == null) {
                        denyButton = device.findObject(By.text("DON'T ALLOW"));
                    }

                    if (denyButton != null) {
                        denyButton.click();
                        Thread.sleep(STABILIZE_DELAY_MS);
                        dialogsDismissed++;
                        Log.d(TAG, "❌ Denied permission (as per test config)");
                    } else {
                        device.pressBack();
                        Thread.sleep(STABILIZE_DELAY_MS);
                        dialogsDismissed++;
                        Log.d(TAG, "❌ Dismissed permission (deny via back)");
                    }
                }
                return; // Found and handled
            }
        }

        // ALSO check without package filter (some Android versions don't include
        // package)
        for (String allowText : allowTexts) {
            UiObject2 allowButton = device.findObject(By.text(allowText));

            if (allowButton != null) {
                dialogsDetected++;
                Log.d(TAG, "🚨 Detected: Permission Dialog (no pkg filter, button: '" + allowText + "')");

                if (config.permissionAction.equals("allow")) {
                    allowButton.click();
                    Thread.sleep(STABILIZE_DELAY_MS);
                    dialogsDismissed++;
                    Log.d(TAG, "✅ Granted permission");
                }
                return;
            }
        }
    }

    /**
     * Handle location permission specific dialogs
     */
    private void handleLocationPermission() throws InterruptedException {
        if (config.permissionAction.equals("ignore")) {
            return;
        }

        UiObject2 preciseLocation = device.findObject(By.text("Precise"));
        UiObject2 approximateLocation = device.findObject(By.text("Approximate"));

        if (preciseLocation != null || approximateLocation != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Location Precision Dialog");
            Log.d(TAG, "   Test wants: " + config.locationPrecision);

            if (config.locationPrecision.equals("precise") && preciseLocation != null) {
                preciseLocation.click();
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "✅ Selected precise location (as per test config)");
            } else if (config.locationPrecision.equals("approximate") && approximateLocation != null) {
                approximateLocation.click();
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "✅ Selected approximate location (as per test config)");
            }
        }
    }

    /**
     * Handle notification permission dialogs
     */
    private void handleNotificationPermission() throws InterruptedException {
        if (config.notificationAction.equals("ignore")) {
            return;
        }

        UiObject2 allowNotifications = device.findObject(
                By.text("Allow").desc("Allow"));

        if (allowNotifications != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Notification Permission Dialog");
            Log.d(TAG, "   Test directive: " + config.notificationAction);

            if (config.notificationAction.equals("allow")) {
                allowNotifications.click();
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "✅ Allowed notifications (as per test config)");
            } else if (config.notificationAction.equals("deny")) {
                UiObject2 denyButton = device.findObject(By.text("Don't allow"));
                if (denyButton != null) {
                    denyButton.click();
                } else {
                    device.pressBack();
                }
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "❌ Denied notifications (as per test config)");
            }
        }
    }

    /**
     * Handle generic system alerts
     */
    private void handleSystemAlerts() throws InterruptedException {
        if (config.systemDialogAction.equals("ignore")) {
            return;
        }

        // Generic "OK" button
        UiObject2 okButton = device.findObject(By.text("OK"));
        if (okButton != null && isSystemDialog(okButton)) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: System Alert (OK button)");
            Log.d(TAG, "   Test directive: " + config.systemDialogAction);

            if (config.systemDialogAction.equals("dismiss")) {
                okButton.click();
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "✅ Dismissed system alert (as per test config)");
            }
        }

        // Generic "Continue" button
        UiObject2 continueButton = device.findObject(By.text("Continue"));
        if (continueButton != null && isSystemDialog(continueButton)) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: System Dialog (Continue button)");
            if (config.systemDialogAction.equals("dismiss")) {
                continueButton.click();
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "✅ Clicked Continue (as per test config)");
            }
        }

        // Generic "Got it" button
        UiObject2 gotItButton = device.findObject(By.text("Got it"));
        if (gotItButton != null && isSystemDialog(gotItButton)) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: System Dialog (Got it button)");
            if (config.systemDialogAction.equals("dismiss")) {
                gotItButton.click();
                Thread.sleep(STABILIZE_DELAY_MS);
                dialogsDismissed++;
                Log.d(TAG, "✅ Clicked Got it (as per test config)");
            }
        }
    }

    /**
     * Handle "App Not Responding" (ANR) dialogs
     */
    private void handleAppNotRespondingDialog() throws InterruptedException {
        UiObject2 waitButton = device.findObject(By.text("Wait"));

        if (waitButton != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: App Not Responding Dialog");
            Log.d(TAG, "   Action: Always wait (critical for test)");
            waitButton.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Clicked Wait");
        }
    }

    /**
     * Check if element is from system dialog
     */
    private boolean isSystemDialog(UiObject2 element) {
        if (element == null)
            return false;

        String pkg = element.getApplicationPackage();
        return pkg != null && (pkg.contains("android") ||
                pkg.contains("com.google.android.permissioncontroller") ||
                pkg.contains("com.android.systemui"));
    }

    /**
     * Configuration holder class
     */
    private static class WatcherConfiguration {
        String permissionAction = "allow";
        String locationPrecision = "precise";
        String notificationAction = "allow";
        String systemDialogAction = "dismiss";
        String googlePickerAction = "dismiss";

        WatcherConfiguration(JSONObject json) throws Exception {
            if (json.has("permissions")) {
                permissionAction = json.getString("permissions");
            }
            if (json.has("location")) {
                locationPrecision = json.getString("location");
            }
            if (json.has("notifications")) {
                notificationAction = json.getString("notifications");
            }
            if (json.has("systemDialogs")) {
                systemDialogAction = json.getString("systemDialogs");
            }
            if (json.has("googlePicker")) {
                googlePickerAction = json.getString("googlePicker");
            }
        }

        static WatcherConfiguration getDefault() {
            try {
                return new WatcherConfiguration(new JSONObject());
            } catch (Exception e) {
                return null;
            }
        }

        boolean shouldHandleGooglePicker() {
            return googlePickerAction.equals("dismiss");
        }
    }
}
