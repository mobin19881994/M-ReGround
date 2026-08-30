package com.mreground.munloop.interception

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class UnloopAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Hook for foreground app interception. Forward package names to Flutter in production.
    }

    override fun onInterrupt() {
        // Intentionally no-op.
    }
}
