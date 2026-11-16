
package com.example.pogetit_quests

import android.location.Address
import android.location.Geocoder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "pogetit/location"
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            if (call.method != "getAddress") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val latitude = call.argument<Double>("latitude")
            val longitude = call.argument<Double>("longitude")

            if (latitude == null || longitude == null) {
                result.error(
                    "INVALID_COORDINATES",
                    "Latitude or longitude is missing",
                    null
                )
                return@setMethodCallHandler
            }

            if (!Geocoder.isPresent()) {
                result.error(
                    "GEOCODER_UNAVAILABLE",
                    "No geocoding service is available",
                    null
                )
                return@setMethodCallHandler
            }

            val geocoder = Geocoder(
                applicationContext,
                Locale.getDefault()
            )

            fun sendAddress(addresses: List<Address>) {
                if (addresses.isEmpty()) {
                    result.success(null)
                    return
                }

                val address = addresses.first()

                val parts = listOfNotNull(
                    address.subLocality,
                    address.locality,
                    address.adminArea
                ).filter { it.isNotBlank() }.distinct()

                result.success(
                    parts.takeIf { it.isNotEmpty() }
                        ?.joinToString(", ")
                )
            }

            try {
                if (Build.VERSION.SDK_INT >= 33) {
                    geocoder.getFromLocation(
                        latitude,
                        longitude,
                        1,
                        object : Geocoder.GeocodeListener {
                            override fun onGeocode(
                                addresses: List<Address>
                            ) {
                                runOnUiThread {
                                    sendAddress(addresses)
                                }
                            }

                            override fun onError(
                                errorMessage: String?
                            ) {
                                runOnUiThread {
                                    result.error(
                                        "GEOCODING_FAILED",
                                        errorMessage
                                            ?: "Address lookup failed",
                                        null
                                    )
                                }
                            }
                        }
                    )
                } else {
                    executor.execute {
                        try {
                            @Suppress("DEPRECATION")
                            val addresses =
                                geocoder.getFromLocation(
                                    latitude,
                                    longitude,
                                    1
                                ).orEmpty()

                            runOnUiThread {
                                sendAddress(addresses)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "GEOCODING_FAILED",
                                    e.message,
                                    null
                                )
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                result.error(
                    "GEOCODING_FAILED",
                    e.message,
                    null
                )
            }
        }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
