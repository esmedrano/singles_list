plugins {
  id("com.android.application")
  id("kotlin-android")
  id("dev.flutter.flutter-gradle-plugin")
  id("com.google.gms.google-services")
}

android {
  namespace = "com.example.integra_date"
  compileSdk = 36
  ndkVersion = "27.0.12077973"

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }

  kotlinOptions {
    jvmTarget = "11"
  }

  defaultConfig {
    applicationId = "com.example.integra_date"
    minSdk = flutter.minSdkVersion.toInt()
    targetSdk = flutter.targetSdkVersion.toInt()
    versionCode = flutter.versionCode
    versionName = flutter.versionName
  }

  buildTypes {
    getByName("release") {
      isMinifyEnabled = true // Only set to true if "proguardrules-rules.pro" are tested or else may interfere with firebase
      isShrinkResources = true // Only set to true if "proguardrules-rules.pro" are tested or else may interfere with firebase
      proguardFiles(
          getDefaultProguardFile("proguard-android-optimize.txt"),
          "proguard-rules.pro"
      )
      signingConfig = signingConfigs.getByName("debug") // Use debug signing for testing    
    }
  }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    implementation("com.google.android.play:integrity:1.3.0")
}

flutter {
  source = "../.."
}
