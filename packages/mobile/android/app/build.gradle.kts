import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nelsongrey.modulosquares.app.android"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Use Java 17 to match recent Android Gradle Plugin and Flutter requirements
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
    applicationId = "com.nelsongrey.modulosquares.app.android"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Load signing properties from local.properties or environment variables
            val keystorePropertiesFile = rootProject.file("local.properties")
            val keystoreProperties = Properties()

            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(keystorePropertiesFile.inputStream())
            }

            // Try local.properties first, then environment variables
            val storeFile = keystoreProperties.getProperty("storeFile")
                ?: System.getenv("ANDROID_KEYSTORE_PATH")
                ?: "upload-keystore.jks"

            val storePassword = keystoreProperties.getProperty("storePassword")
                ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
                ?: "android"

            val keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: System.getenv("ANDROID_KEY_ALIAS")
                ?: "upload"

            val keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: System.getenv("ANDROID_KEY_PASSWORD")
                ?: "android"

            this.storeFile = file(storeFile)
            this.storePassword = storePassword
            this.keyAlias = keyAlias
            this.keyPassword = keyPassword
        }
    }

    buildTypes {
        release {
            // Use proper release signing config
            signingConfig = signingConfigs.getByName("release")

            // Enable R8 full mode for better optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Apply Google Services only if a matching google-services.json is present.
// This prevents Gradle sync/build failures when the Firebase Android app package
// doesn’t match the appId during local development.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
