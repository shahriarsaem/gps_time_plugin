package com.shahriarsaem.gpstimeplugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

/** GpsTimePlugin */
class GpsTimePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var gpsTimeHelper: GpsTimeHelper? = null

    // Scope for collecting flows and forwarding to Flutter EventSink
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext

        gpsTimeHelper = GpsTimeHelper(context)

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "gps_time_plugin")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "gps_time_plugin/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startListening" -> {
                gpsTimeHelper?.startListening()
                result.success(null)
            }
            "stopListening" -> {
                gpsTimeHelper?.stopListening()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        gpsTimeHelper?.stopListening()
        scope.cancel()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startFlowCollection()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startFlowCollection() {
        val gpsHelper = gpsTimeHelper ?: return

        combine(
            gpsHelper.trustedTime,
            gpsHelper.gpsAccuracy,
            gpsHelper.ageSeconds,
            gpsHelper.statusMessage,
        ) { trustedTime, accuracy, ageSeconds, status ->
            mapOf(
                "trustedTime" to trustedTime,
                "accuracy" to accuracy,
                "ageSeconds" to ageSeconds,
                "deviceTime" to System.currentTimeMillis(),
                "statusMessage" to status,
            )
        }.onEach { data ->
            eventSink?.success(data)
        }.launchIn(scope)
    }
}
