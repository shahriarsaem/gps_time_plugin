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
 * ## How trusted time is computed
 *
 * Android's [Location.getTime] reflects the system clock at fix time — it can be
 * manipulated by simply changing the device clock. To work around this, we instead
 * use [Location.getElapsedRealtimeNanos]: a **monotonic** counter that measures
 * nanoseconds since last boot. It is unaffected by manual clock changes.
 *
 * At the moment of a GPS fix we know:
 *   gpsSatelliteUtcMs ≈ location.time           (GPS UTC, but can be manipulated pre-fix)
 *   fixMonotonicNanos  = location.elapsedRealtimeNanos
 *
 * We store [bootEpochOffsetMs]: the calculated offset such that
 *   trustedUtcMs = bootEpochOffsetMs + (SystemClock.elapsedRealtimeNanos() / 1_000_000)
 *
 * Once we have a GPS fix, this offset is computed from GPS data and is immune
 * to subsequent clock tampering.
 *
 * IMPORTANT: The caller must obtain [android.Manifest.permission.ACCESS_FINE_LOCATION]
 * permission before calling [startListening].
 */
class GpsTimeHelper(private val context: Context) {

    private val locationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    // Offset from boot (monolithic epoch) to GPS UTC in milliseconds.
    // Once set from a GPS fix, this is tamper-resistant.
    private var bootEpochOffsetMs: Long? = null

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

            _statusMessage.value = "Starting... searching for GPS signal."

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
                    "Waiting for location fix... (may take 30-90s outdoors)"
            }

            for (provider in providers) {
                locationManager.requestLocationUpdates(
                    provider,
                    2000L,  // min 2s interval
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

        // Sanity check: reject fixes from future or impossibly old (> 5 min)
        val isValidFix = fixElapsedNanos > 0 && fixAgeNanos in 0..300_000_000_000L

        if (isValidFix) {
            // Compute the offset: if we add this to any future elapsedRealtimeNanos,
            // we get correct UTC — even if the system clock is changed afterwards.
            // bootEpochOffsetMs = fixUtcMs - fixElapsedMs
            val fixElapsedMs = fixElapsedNanos / 1_000_000
            bootEpochOffsetMs = fixUtcMillis - fixElapsedMs
        }

        // Compute current trusted time using the stored offset + current monotonic time
        val currentTrustedTimeMs: Long
        val ageSeconds: Long

        val offset = bootEpochOffsetMs
        if (offset != null) {
            val nowElapsedMs = nowElapsedNanos / 1_000_000
            currentTrustedTimeMs = offset + nowElapsedMs

            val fixElapsedMs = fixElapsedNanos / 1_000_000
            ageSeconds = (nowElapsedMs - fixElapsedMs) / 1000
        } else {
            // No valid fix yet — fallback
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
