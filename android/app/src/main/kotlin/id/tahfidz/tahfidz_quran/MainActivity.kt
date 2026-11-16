package id.tahfidz.tahfidz_quran

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "id.tahfidz.tahfidz_quran/backup"
    private val saveCode = 47001
    private val openCode = 47002
    private val maxBackupBytes = 4 * 1024 * 1024
    private var waiting: MethodChannel.Result? = null
    private var pendingBackup: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (waiting != null) {
                    result.error("busy", "A backup file operation is already open", null)
                    return@setMethodCallHandler
                }
                try {
                    when (call.method) {
                        "saveBackup" -> {
                            val payload = call.argument<String>("content")
                            if (payload == null ||
                                payload.toByteArray(Charsets.UTF_8).size > maxBackupBytes) {
                                result.error("size", "Invalid backup size", null)
                                return@setMethodCallHandler
                            }
                            val title = call.argument<String>("fileName")
                                ?: "tahfidz-quran-backup.json"
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/json"
                                putExtra(Intent.EXTRA_TITLE, title)
                            }
                            waiting = result
                            pendingBackup = payload
                            startActivityForResult(intent, saveCode)
                        }
                        "openBackup" -> {
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "*/*"
                                addCategory(Intent.CATEGORY_OPENABLE)
                            }
                            waiting = result
                            startActivityForResult(intent, openCode)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    waiting = null
                    pendingBackup = null
                    result.error("file", error.message ?: "File operation failed", null)
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveCode && requestCode != openCode) return
        val reply = waiting ?: return
        waiting = null
        try {
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                reply.success(null)
                return
            }
            if (requestCode == saveCode) {
                val bytes = (pendingBackup ?: "").toByteArray(Charsets.UTF_8)
                if (bytes.size > maxBackupBytes) error("Backup too large")
                val out = contentResolver.openOutputStream(uri)
                    ?: error("Cannot write selected file")
                out.use { it.write(bytes) }
                reply.success(true)
            } else {
                val input = contentResolver.openInputStream(uri)
                    ?: error("Cannot read selected file")
                val bytes = ByteArrayOutputStream()
                input.use { stream ->
                    val buffer = ByteArray(8192)
                    while (true) {
                        val count = stream.read(buffer)
                        if (count < 0) break
                        if (bytes.size() + count > maxBackupBytes) error("Backup exceeds 4 MB")
                        bytes.write(buffer, 0, count)
                    }
                }
                reply.success(bytes.toString(Charsets.UTF_8.name()))
            }
        } catch (error: Exception) {
            reply.error("file", error.message ?: "File operation failed", null)
        } finally {
            pendingBackup = null
        }
    }
}
