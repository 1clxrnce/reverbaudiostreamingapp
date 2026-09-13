import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "codes.afk.simple_player"
    // innertubex-android requires consumers to compile against API 37+
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "codes.afk.simple_player"
        // mpv_audio_kit requires Android 7.0+ (API 24)
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ── YouTube Music stream resolution ───────────────────────────────────
    // InnerTube extraction: client ladder, cipher/n-transform, format
    // selection — GPL-3.0, from the Metrolist project. Same dep as sunoh.
    implementation("com.github.MetrolistGroup.innertubex:innertubex-android:v0.2.6")

    // Coroutines — the extractor's public API is suspend
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    // Ktor + OkHttp — InnerTubeX requires a caller-owned HttpClient
    implementation("io.ktor:ktor-client-okhttp:3.0.3")
    implementation("io.ktor:ktor-client-content-negotiation:3.0.3")
    implementation("io.ktor:ktor-serialization-kotlinx-json:3.0.3")
    implementation("io.ktor:ktor-client-encoding:3.0.3")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // JSON — used by the PO-token WebView to parse BotGuard payloads
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    // ArrayMap — used by the PO-token WebView
    implementation("androidx.collection:collection-ktx:1.4.5")
}
