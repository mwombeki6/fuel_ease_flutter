plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fuelease.fuel_ease_flutter"
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
        applicationId = "com.fuelease.fuel_ease_flutter"
        minSdk = flutter.minSdkVersion // flutter_secure_storage (encryptedSharedPreferences) + geolocator require API 23+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Release signing — override by setting these properties in
        // ~/.gradle/gradle.properties or via CI environment variables:
        //   FUELEASE_KEYSTORE_PATH, FUELEASE_KEYSTORE_PASSWORD,
        //   FUELEASE_KEY_ALIAS, FUELEASE_KEY_PASSWORD
        create("release") {
            val keystorePath = System.getenv("FUELEASE_KEYSTORE_PATH")
                ?: project.findProperty("FUELEASE_KEYSTORE_PATH") as String?
            if (keystorePath != null) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("FUELEASE_KEYSTORE_PASSWORD")
                    ?: project.findProperty("FUELEASE_KEYSTORE_PASSWORD") as String?
                keyAlias = System.getenv("FUELEASE_KEY_ALIAS")
                    ?: project.findProperty("FUELEASE_KEY_ALIAS") as String?
                keyPassword = System.getenv("FUELEASE_KEY_PASSWORD")
                    ?: project.findProperty("FUELEASE_KEY_PASSWORD") as String?
            }
        }
    }

    buildTypes {
        release {
            val hasKeystore = System.getenv("FUELEASE_KEYSTORE_PATH") != null
                || project.hasProperty("FUELEASE_KEYSTORE_PATH")
            signingConfig = if (hasKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug") // fallback for local dev
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
