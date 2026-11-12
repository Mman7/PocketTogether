import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pockettogether"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_25
        targetCompatibility = JavaVersion.VERSION_25
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ffta"
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

    signingConfigs {
        create("release") {
            val requiredProperties = listOf(
                "storePassword",
                "keyPassword",
                "keyAlias",
                "storeFile",
            )
            val missingProperties = requiredProperties.filter {
                keystoreProperties.getProperty(it).isNullOrBlank()
            }
            if (missingProperties.isNotEmpty()) {
                throw GradleException(
                    "Missing release signing properties in ${keystorePropertiesFile}: " +
                        missingProperties.joinToString(", ")
                )
            }

            val releaseKeystoreFile = file(keystoreProperties.getProperty("storeFile"))
            if (!releaseKeystoreFile.isFile) {
                throw GradleException(
                    "Release keystore does not exist: ${releaseKeystoreFile.absolutePath}"
                )
            }

            storePassword = keystoreProperties.getProperty("storePassword")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            storeFile = releaseKeystoreFile
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25
    }
}

flutter {
    source = "../.."
}
