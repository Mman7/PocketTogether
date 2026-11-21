
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ffta"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.ffta"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
                    "Missing release signing properties: " +
                        missingProperties.joinToString(", ")
                )
            }

            val releaseKeystoreFile =
                file(keystoreProperties.getProperty("storeFile"))

            if (!releaseKeystoreFile.isFile) {
                throw GradleException(
                    "Release keystore does not exist: " +
                        releaseKeystoreFile.absolutePath
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
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
