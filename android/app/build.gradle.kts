plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystore = System.getenv("ORGANIZA_KEYSTORE_PATH")
val releasePassword = System.getenv("ORGANIZA_SIGNING_PASSWORD")

android {
    namespace = "com.danielcdesk.organiza"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.danielcdesk.organiza"
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
            if (!releaseKeystore.isNullOrBlank() && !releasePassword.isNullOrBlank()) {
                signingConfig = signingConfigs.getByName("organizaRelease")
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
