package com.danielcdesk.organiza

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val channelName = "com.danielcdesk.organiza/backup_folder"
    private val treeRequest = 41091
    private var pendingTree: MethodChannel.Result? = null
    private val backupName = Regex("^organiza-auto-[A-Za-z0-9._-]+\\.organizabak$")
    private val preferences by lazy { getSharedPreferences("backup_folder", MODE_PRIVATE) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "choose" -> {
                            if (pendingTree != null) {
                                result.error("busy", "Seletor de pasta em uso.", null)
                            } else {
                                pendingTree = result
                                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                                }
                                startActivityForResult(intent, treeRequest)
                            }
                        }
                        "configured" -> result.success(selectedTree() != null)
                        "save" -> {
                            val name = call.argument<String>("name") ?: error("Nome ausente")
                            val source = call.argument<String>("source") ?: error("Arquivo ausente")
                            require(backupName.matches(name)) { "Nome de backup inválido" }
                            val tree = selectedTree() ?: error("Escolha uma pasta de backup")
                            val file = File(source)
                            require(file.isFile) { "Arquivo de backup ausente" }
                            val parent = DocumentsContract.buildDocumentUriUsingTree(
                                tree, DocumentsContract.getTreeDocumentId(tree)
                            )
                            val document = DocumentsContract.createDocument(
                                contentResolver, parent, "application/octet-stream", name
                            ) ?: error("Não foi possível criar o backup")
                            try {
                                contentResolver.openOutputStream(document, "w")!!.use { output ->
                                    file.inputStream().use { input -> input.copyTo(output) }
                                    output.flush()
                                }
                            } catch (failure: Exception) {
                                DocumentsContract.deleteDocument(contentResolver, document)
                                throw failure
                            }
                            result.success(name)
                        }
                        "list" -> result.success(listBackups().map { it.first })
                        "delete" -> {
                            val name = call.argument<String>("name") ?: error("Nome ausente")
                            require(backupName.matches(name)) { "Nome de backup inválido" }
                            val match = listBackups().firstOrNull { it.first == name }
                            if (match != null) DocumentsContract.deleteDocument(contentResolver, match.second)
                            result.success(null)
                        }
                        "secretRead" -> result.success(readSecret())
                        "secretWrite" -> {
                            val value = call.argument<String>("value") ?: error("Senha ausente")
                            writeSecret(value)
                            result.success(null)
                        }
                        "secretDelete" -> {
                            preferences.edit().remove("secret").apply()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (failure: Exception) {
                    result.error("backup_folder", failure.message ?: "Falha na pasta de backup", null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != treeRequest) return
        val pending = pendingTree ?: return
        pendingTree = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(false)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            preferences.edit().putString("uri", uri.toString()).apply()
            pending.success(true)
        } catch (failure: Exception) {
            pending.error("backup_folder", failure.message, null)
        }
    }

    private fun selectedTree(): Uri? {
        val raw = preferences.getString("uri", null) ?: return null
        val uri = Uri.parse(raw)
        val granted = contentResolver.persistedUriPermissions.any {
            it.uri == uri && it.isReadPermission && it.isWritePermission
        }
        return if (granted) uri else null
    }

    private fun listBackups(): List<Pair<String, Uri>> {
        val tree = selectedTree() ?: return emptyList()
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree)
        )
        val entries = mutableListOf<Pair<String, Uri>>()
        contentResolver.query(
            children,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_DOCUMENT_ID),
            null, null, null
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val name = cursor.getString(0)
                if (backupName.matches(name)) {
                    entries.add(name to DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(1)))
                }
            }
        }
        return entries
    }

    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val alias = "organiza_backup_secret_v1"
        val existing = store.getKey(alias, null)
        if (existing is SecretKey) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build())
        return generator.generateKey()
    }

    private fun writeSecret(value: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val payload = cipher.iv + encrypted
        preferences.edit().putString("secret", Base64.encodeToString(payload, Base64.NO_WRAP)).apply()
    }

    private fun readSecret(): String? {
        val encoded = preferences.getString("secret", null) ?: return null
        val payload = Base64.decode(encoded, Base64.NO_WRAP)
        require(payload.size > 28) { "Senha protegida inválida" }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, payload.copyOfRange(0, 12)))
        return String(cipher.doFinal(payload.copyOfRange(12, payload.size)), Charsets.UTF_8)
    }
}
