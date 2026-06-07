import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val pangolinLocalProperties = Properties()
val pangolinLocalFile = rootProject.file("pangolin-local.properties")
if (pangolinLocalFile.exists()) {
    pangolinLocalFile.inputStream().use { pangolinLocalProperties.load(it) }
}

android {
    namespace = "com.owxo.pangolin_content_sdk_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId =
            pangolinLocalProperties.getProperty("applicationId")
                ?: "com.owxo.pangolin_content_sdk_example"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["APPLOG_SCHEME"] =
            pangolinLocalProperties.getProperty("applogScheme")
                ?: "rangersapplog.pangolincontentsdk.example"
        manifestPlaceholders["PANGLE_APP_ID"] =
            pangolinLocalProperties.getProperty("pangleAppId") ?: ""
        manifestPlaceholders["PANGLE_AD_APP_ID"] =
            pangolinLocalProperties.getProperty("pangleAdAppId") ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
