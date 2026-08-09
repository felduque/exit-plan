import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Analytics + Remote Config need this plugin to inject
// google-services.json into the build. Applied only when the file exists —
// same discipline as the upload key and exitplan.env elsewhere in this file:
// a checkout without Firebase credentials still builds, just with Firebase
// silently absent rather than a hard Gradle failure.
if (rootProject.file("app/google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// The upload key EAS generated for @felduque27/exitplan. Kept out of the repo,
// so a checkout without it still builds — release just falls back to debug keys.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasUploadKey = keystoreProperties.getProperty("storeFile") != null

// The same exitplan.env that --dart-define-from-file reads, parsed here too.
//
// The AdMob app id cannot travel by --dart-define: MobileAds.initialize()
// crashes outright without it in the manifest, which is decided long before any
// Dart runs. Reading it from the one credentials file — rather than a separate
// -P flag — means there is a single thing to remember on a release build
// instead of two that fail in different ways when forgotten.
//
// KEY=VALUE with # comments parses identically as a .env and as a Java
// properties file, which is the only reason this works.
val envFile = rootProject.file("../exitplan.env")
val env = Properties().apply {
    if (envFile.exists()) {
        envFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.dg.developer.exitplan"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications, which uses java.time to work
        // out when a scheduled call should fire. minSdk here is 23 and
        // java.time only exists from 26, so without this the build fails
        // outright on :app:checkDebugAarMetadata rather than at runtime.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // The id the Expo build published under. It is what Play uses to decide
        // that an upload is an *update* to the existing listing rather than a
        // new app, and it is immutable once published — do not "tidy" it.
        applicationId = "com.dg.developer.exitplan"
        // audio_service needs 23+.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Same discipline as the upload key above: a checkout without the
        // credentials file still builds, and the fallback is Google's public
        // *test* app id — inert rather than wrong. Set ADMOB_APP_ID in
        // exitplan.env to ship real ads.
        manifestPlaceholders["admobAppId"] =
            env.getProperty("ADMOB_APP_ID")?.takeIf { it.isNotBlank() }
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                // No key.properties here — sign with debug keys so
                // `flutter run --release` still works locally.
                signingConfigs.getByName("debug")
            }
            // proguard-rules.pro exists solely to stop R8 failing on the
            // unused halves of the TikTok SDK. See the file for the reasoning.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

dependencies {
    // The other half of isCoreLibraryDesugaringEnabled above: the flag turns
    // the rewriting on, this supplies the backported java.time classes it
    // rewrites calls into.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // The Play Install Referrer library. Not optional despite being an explicit
    // extra: it is how the TikTok SDK learns which ad click led to the install,
    // which is the only reason that SDK is in this app. Without it the SDK still
    // runs, still sends its events, and attributes almost nothing — a silent
    // failure rather than a loud one.
    implementation("com.android.installreferrer:installreferrer:2.2")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
