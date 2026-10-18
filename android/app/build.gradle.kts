plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystore = System.getenv("ORGANIZA_KEYSTORE_PATH")
val releasePassword = System.getenv("ORGANIZA_SIGNING_PASSWORD")
val previewBuild = System.getenv("ORGANIZA_PREVIEW_BUILD") == "1"

android {
    namespace = "com.danielcdesk.organiza"
    // file_picker's Android lifecycle bridge is built against API 36.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.danielcdesk.organiza"
        if (previewBuild) {
            applicationIdSuffix = ".preview"
        }
        manifestPlaceholders["applicationLabel"] = if (previewBuild) "Organiza Teste" else "Organiza"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    if (!releaseKeystore.isNullOrBlank() && !releasePassword.isNullOrBlank()) {
        signingConfigs {
            create("organizaRelease") {
                storeFile = file(releaseKeystore)
                storePassword = releasePassword
                keyAlias = "organiza"
                keyPassword = releasePassword
            }
        }
    }

    buildTypes {
        release {
            if (previewBuild) {
                signingConfig = signingConfigs.getByName("debug")
            } else if (!releaseKeystore.isNullOrBlank() && !releasePassword.isNullOrBlank()) {
                signingConfig = signingConfigs.getByName("organizaRelease")
            } else if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
                throw GradleException("Release exige ORGANIZA_KEYSTORE_PATH e ORGANIZA_SIGNING_PASSWORD. Para APK de teste separado, use ORGANIZA_PREVIEW_BUILD=1.")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
