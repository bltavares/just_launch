package com.bltavares.package_manager

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class PackageManagerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private val jobContext = CoroutineScope(Dispatchers.IO) + SupervisorJob()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "package_manager")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAllApps" -> jobContext.launch { getAllApps(result) }
            "launchApp" -> call.argument<String>("packageName")
                ?.also { jobContext.launch { launchApp(it, result) } }
                ?: run {
                    result.error(
                        "missing_argument",
                        "required packageName not passed as a map",
                        null
                    )
                }
            "launchSettings" -> call.argument<String>("packageName")
                ?.also { jobContext.launch { launchAppSettings(it, result) } }
                ?: run {
                    result.error(
                        "missing_argument",
                        "required packageName not passed as a map",
                        null
                    )
                }
            else -> result.notImplemented()
        }
    }

    private fun launchAppSettings(packageName: String, result: Result) {
        context?.apply {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", packageName, null)
            )
            startActivity(intent)
            return result.success(true)
        }
        result.error("package_manager_error", "Activity not found", null)
    }

    private fun launchApp(packageName: String, result: Result) {
        context?.apply {
            packageManager.getLaunchIntentForPackage(packageName)?.also {
                startActivity(it)
                return result.success(true)
            }
        }
        result.error("package_manager_error", "Activity not found", null)
    }


    private fun getAllApps(result: Result) {
        context?.apply {
            val intent = Intent(Intent.ACTION_MAIN, null).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val manager: PackageManager = packageManager
            val appList: List<ResolveInfo> = manager.queryIntentActivities(intent, 0)
            val output = appList.mapNotNull {
                val app: ApplicationInfo = manager.getApplicationInfo(
                    it.activityInfo.packageName, PackageManager.GET_META_DATA
                )
                if (manager.getLaunchIntentForPackage(app.packageName) != null) {
                    mapOf(
                        "label" to app.loadLabel(manager).toString(),
                        "package" to app.packageName,
                    )
                } else {
                    null
                }
            }
            result.success(output)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
        jobContext.cancel("Plugin detached")
    }
}
