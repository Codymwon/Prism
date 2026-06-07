package com.prism.prism

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.concurrent.thread

class ShareActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle the incoming send intent
        if (intent?.action == Intent.ACTION_SEND && "text/plain" == intent.type) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!sharedText.isNullOrEmpty()) {
                saveToInbox(sharedText)
            } else {
                Toast.makeText(this, "No content shared", Toast.LENGTH_SHORT).show()
                finish()
            }
        } else {
            finish()
        }
    }

    private fun saveToInbox(text: String) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val baseDir = prefs.getString("flutter.baseVaultsDirectory", null)
        val activeVault = prefs.getString("flutter.activeVaultName", "My Vault")

        if (baseDir.isNullOrEmpty()) {
            Toast.makeText(
                this,
                "Please open Prism first to initialize your vault.",
                Toast.LENGTH_LONG
            ).show()
            finish()
            return
        }

        val vaultFile = File(baseDir, activeVault)
        if (!vaultFile.exists()) {
            Toast.makeText(
                this,
                "Active vault not found. Please open Prism first.",
                Toast.LENGTH_LONG
            ).show()
            finish()
            return
        }

        val vaultPath = vaultFile.absolutePath

        thread {
            try {
                // Strictly target Inbox.md in the root of the active vault directory.
                // This isolates the clipper's inbox note from user-created notes
                // which are saved with format 'inbox-<uuid>.md'.
                val inboxFile = File(vaultPath, "Inbox.md")

                // Create the note if it doesn't exist
                if (!inboxFile.exists()) {
                    inboxFile.parentFile?.mkdirs()
                    inboxFile.writeText("# Inbox\n\n")
                }

                // Parse the shared text for URLs
                val urlRegex = Regex("""(https?://[^\s]+)""")
                val matchResult = urlRegex.find(text)

                val contentToAppend = if (matchResult != null) {
                    val url = matchResult.value
                    // Extract title from the rest of the text
                    val titleCandidate = text.replace(url, "")
                        .trim()
                        .removePrefix("-").removeSuffix("-")
                        .removePrefix(":").removeSuffix(":")
                        .trim()

                    if (titleCandidate.isNotEmpty()) {
                        "[$titleCandidate]($url)"
                    } else {
                        "[$url]($url)"
                    }
                } else {
                    text.trim()
                }

                // Format the log entry
                val timeStamp = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).format(Date())
                val formattedEntry = "\n- [$timeStamp] $contentToAppend"

                // Write to disk
                inboxFile.appendText(formattedEntry)
                inboxFile.setLastModified(System.currentTimeMillis())

                // Toast success
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(this, "Saved to Inbox", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(this, "Failed to save: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
                }
            } finally {
                Handler(Looper.getMainLooper()).post {
                    finish()
                }
            }
        }
    }
}
