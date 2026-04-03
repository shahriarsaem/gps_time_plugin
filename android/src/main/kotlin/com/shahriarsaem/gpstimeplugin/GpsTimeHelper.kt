package com.shahriarsaem.gpstimeplugin

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.SystemClock
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Helper class to extract GPS-synced trusted time from device location providers.
 *
 * Uses [LocationManager] with both GPS and Network providers.
 * The trusted time is calculated by adjusting the fix's UTC timestamp with
 * the elapsed time since the fix was captured, using [SystemClock.elapsedRealtimeNanos].
 *
 * IMPORTANT: The caller must obtain [android.Manifest.permission.ACCESS_FINE_LOCATION]
 * permission before calling [startListening].
 */
class GpsTimeHelper(private val context: Context) {

    private val locationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    private val _trustedTime = MutableStateFlow<Long?>(null)
    val trustedTime: StateFlow<Long?> = _trustedTime.asStateFlow()

    private val _statusMessage = MutableStateFlow("Waiting for GPS...")
    val statusMessage: StateFlow<String> = _statusMessage.asStateFlow()

    private val _gpsAccuracy = MutableStateFlow<Float?>(null)
    val gpsAccuracy: StateFlow<Float?> = _gpsAccuracy.asStateFlow()

    private val _ageSeconds = MutableStateFlow<Long?>(null)
    val ageSeconds: StateFlow<Long?> = _ageSeconds.asStateFlow()

    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            updateTimeFromLocation(location, location.provider ?: "Unknown", isLastKnown = false)
        }

        override fun onProviderEnabled(provider: String) {}

        override fun onProviderDisabled(provider: String) {
            _statusMessage.value = "GPS Provider Disabled"
        }
    }

    @SuppressLint("MissingPermission")
    fun startListening() {
        try {
            val providers = mutableListOf<String>()

            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                providers.add(LocationManager.GPS_PROVIDER)
            }
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                providers.add(LocationManager.NETWORK_PROVIDER)
            }

            if (providers.isEmpty()) {
                _statusMessage.value =
                    "No location providers enabled. Enable GPS or WiFi in settings."
                return
            }

            _statusMessage.value = "Checking providers: ${providers.joinToString(", ")}..."

            // Emit a cached fix immediately while waiting for a fresh one
            var gotLastKnown = false
            for (provider in providers) {
                val lastKnownLocation = locationManager.getLastKnownLocation(provider)
                if (lastKnownLocation != null) {
                    updateTimeFromLocation(lastKnownLocation, provider, isLastKnown = true)
                    gotLastKnown = true
                    break
                }
            }

            if (!gotLastKnown) {
                _statusMessage.value =
                    "Waiting for location fix... (This may take 30-90 seconds without WiFi/SIM)"
            }

            for (provider in providers) {
                locationManager.requestLocationUpdates(
                    provider,
                    1000L,
                    0f,
                    locationListener
                )
            }
        } catch (e: Exception) {
            _statusMessage.value = "Error: ${e.message}"
        }
    }

    private fun updateTimeFromLocation(
        location: Location,
        provider: String = "GPS",
        isLastKnown: Boolean = false,
    ) {
        val accuracy = location.accuracy
        _gpsAccuracy.value = accuracy

        val fixUtcMillis = location.time
        val fixElapsedNanos = location.elapsedRealtimeNanos
        val nowElapsedNanos = SystemClock.elapsedRealtimeNanos()

        // Compute the age of this fix in nanoseconds
        val fixAgeNanos = nowElapsedNanos - fixElapsedNanos

        // Sanity check: reject fixes that are impossibly old (> 5 minutes) or from future
        val isValidFix = fixElapsedNanos > 0 && fixAgeNanos in 0..300_000_000_000L

        val currentTrustedTimeMs: Long
        val ageSeconds: Long

        if (isValidFix) {
            val elapsedSinceFixMs = fixAgeNanos / 1_000_000
            currentTrustedTimeMs = fixUtcMillis + elapsedSinceFixMs
            ageSeconds = elapsedSinceFixMs / 1000
        } else {
            // Fallback: use fix time directly (may be slightly stale)
            currentTrustedTimeMs = fixUtcMillis
            ageSeconds = 0
        }

        _trustedTime.value = currentTrustedTimeMs
        _ageSeconds.value = ageSeconds

        val statusPrefix = if (isLastKnown) "Cached" else "Fresh"
        val providerName =
            if (provider == LocationManager.GPS_PROVIDER) "GPS" else "Network"

        _statusMessage.value =
            "$statusPrefix $providerName fix (${ageSeconds}s old, accuracy: ${accuracy.toInt()}m)"
    }

    fun stopListening() {
        locationManager.removeUpdates(locationListener)
        _statusMessage.value = "GPS stopped"
    }
}
