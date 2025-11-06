plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.estadio.app"
    compileSdk = 36 // ✅ Usa 34 explícitamente; evita depender solo de flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Requerido por plugins modernos (Maps, Firebase, etc.)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.estadio.app"

        // ✅ Usa al menos 21 para compatibilidad con Google Maps
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Habilita Multidex por seguridad
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            // ⚠️ Puedes mantener esto si tienes muchas dependencias, pero para debug
            // inicial de Maps puedes desactivar minify/shrink temporalmente
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    buildFeatures {
        viewBinding = true
    }

    packaging {
        resources {
            // ✅ Evita conflictos con licencias y duplicados comunes
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // 🔥 Firebase
    implementation("com.google.firebase:firebase-auth:23.1.0")
    implementation("com.google.firebase:firebase-core:21.1.1")

    // 🎨 Material Design
    implementation("com.google.android.material:material:1.12.0")

    // 🗺️ Google Maps y ubicación
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")

    // 🧩 Multidex
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
