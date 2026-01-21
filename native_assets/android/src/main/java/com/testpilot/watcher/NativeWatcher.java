package com.testpilot.watcher;

import androidx.test.uiautomator.UiDevice;
import androidx.test.uiautomator.UiObject2;
import androidx.test.uiautomator.By;
import androidx.test.uiautomator.Until;
import android.util.Log;
import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;

/**
 * Native Dialog Watcher for Flutter Test Pilot
 * Monitors and automatically dismisses native Android dialogs during test execution
 */
public class NativeWatcher {
    private static final String TAG = "TestPilotWatcher";
    private static final long POLL_INTERVAL_MS = 200;
    private static final long STABILIZE_DELAY_MS = 500;

    private UiDevice device;
    private int dialogsDetected = 0;
    private int dialogsDismissed = 0;

    @Test
    public void testWatchForDialogs() throws Exception {
        device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());
        
        Log.d(TAG, "🤖 Native watcher started");
        Log.d(TAG, "Device: " + device.getProductName());
        Log.d(TAG, "Android version: " + android.os.Build.VERSION.RELEASE);

        // Run watcher loop indefinitely
        while (true) {
            try {
                // Check for various dialog types
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
     * Handle Google Credential Picker dialog
     */
    private void handleGoogleCredentialPicker() throws InterruptedException {
        UiObject2 picker = device.findObject(
            By.res("com.google.android.gms:id/credential_picker")
        );

        if (picker != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Google Credential Picker");
            device.pressBack();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Dismissed via back button");
        }
    }

    /**
     * Handle generic permission dialogs
     */
    private void handlePermissionDialogs() throws InterruptedException {
        // Look for "Allow" button in permission controller
        UiObject2 allowButton = device.findObject(
            By.text("Allow").pkg("com.google.android.permissioncontroller")
        );

        if (allowButton != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Permission Dialog (Allow button)");
            allowButton.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Granted permission");
        }

        // Also check for "While using the app" option
        UiObject2 whileUsingButton = device.findObject(
            By.text("While using the app")
        );

        if (whileUsingButton != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Permission Dialog (While using app)");
            whileUsingButton.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Granted permission (while using)");
        }
    }

    /**
     * Handle location permission specific dialogs
     */
    private void handleLocationPermission() throws InterruptedException {
        UiObject2 preciseLocation = device.findObject(
            By.text("Precise")
        );

        if (preciseLocation != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Location Precision Dialog");
            preciseLocation.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Selected precise location");
        }
    }

    /**
     * Handle notification permission dialogs
     */
    private void handleNotificationPermission() throws InterruptedException {
        UiObject2 allowNotifications = device.findObject(
            By.text("Allow").desc("Allow")
        );

        if (allowNotifications != null) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: Notification Permission Dialog");
            allowNotifications.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Allowed notifications");
        }
    }

    /**
     * Handle generic system alerts
     */
    private void handleSystemAlerts() throws InterruptedException {
        // Generic "OK" button
        UiObject2 okButton = device.findObject(By.text("OK"));
        if (okButton != null && isSystemDialog(okButton)) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: System Alert (OK button)");
            okButton.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Dismissed system alert");
        }

        // Generic "Continue" button
        UiObject2 continueButton = device.findObject(By.text("Continue"));
        if (continueButton != null && isSystemDialog(continueButton)) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: System Dialog (Continue button)");
            continueButton.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Clicked Continue");
        }

        // Generic "Got it" button
        UiObject2 gotItButton = device.findObject(By.text("Got it"));
        if (gotItButton != null && isSystemDialog(gotItButton)) {
            dialogsDetected++;
            Log.d(TAG, "🚨 Detected: System Dialog (Got it button)");
            gotItButton.click();
            Thread.sleep(STABILIZE_DELAY_MS);
            dialogsDismissed++;
            Log.d(TAG, "✅ Clicked Got it");
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
        if (element == null) return false;
        
        String pkg = element.getApplicationPackage();
        return pkg != null && (
            pkg.contains("android") ||
            pkg.contains("com.google.android.permissioncontroller") ||
            pkg.contains("com.android.systemui")
        );
    }
}
