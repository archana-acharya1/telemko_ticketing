import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.telemko.telemko_service"
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
        applicationId = "com.telemko.telemko_service"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val alias = keystoreProperties["keyAlias"] as? String
            val keyPass = keystoreProperties["keyPassword"] as? String
            val storeFilePath = keystoreProperties["storeFile"] as? String
            val storePass = keystoreProperties["storePassword"] as? String

            if (alias != null && keyPass != null && storeFilePath != null && storePass != null) {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = file(storeFilePath)
                storePassword = storePass
            }
        }
    }

    buildTypes {
        getByName("release") {
            val releaseConfig = signingConfigs.getByName("release")
            // Fall back to debug signing if release key details are missing
            signingConfig = if (releaseConfig.storeFile != null) releaseConfig else signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}