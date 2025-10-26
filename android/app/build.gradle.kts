import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ymcompany.lifeapp"

    // flutter.compileSdkVersion이 정의돼 있으면 그 값을, 없으면 36 사용
    compileSdk = 36

    // Flutter 플러그인이 노출하는 ndkVersion을 그대로 사용(필요 시)
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.ymcompany.lifeapp"

        // Android 8.0 (API 26) 이상 공식 지원 (health 플러그인 요구사항)
        minSdk = 26
        targetSdk = 36

        versionCode = 1
        versionName = "1.0"

        vectorDrawables.useSupportLibrary = true
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.ymcompany.lifeapp.dev"
        }
        create("staging") {
            dimension = "environment"
            applicationId = "com.ymcompany.lifeapp.staging"
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.ymcompany.lifeapp"
        }
    }

    // 중복 금지: compileOptions 블록은 한 번만!
    compileOptions {
        // Java 17로 통일 (Java 8 obsolete 경고 제거)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // JDK API desugaring (java.time 등)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf("-Xjvm-default=all") // 선택: 인터페이스 default methods 호환
    }

    // (선택) 릴리즈 빌드 서명 미설정 시 debug 키로 임시 서명
    val releaseSigning = signingConfigs.create("release").apply {
        val keystorePropsFile = rootProject.file("android/key.properties")
        if (keystorePropsFile.exists()) {
            val props = Properties().apply {
                FileInputStream(keystorePropsFile).use { load(it) }
            }
            val store = props.getProperty("storeFile")?.let { rootProject.file(it) }
            if (store != null && store.exists()) {
                storeFile = store
            }
            storePassword = props.getProperty("storePassword")
            keyAlias = props.getProperty("keyAlias")
            keyPassword = props.getProperty("keyPassword")
        }

        val env = System.getenv()
        val envStorePath = env["ANDROID_KEYSTORE_PATH"]?.takeIf { it.isNotBlank() }
        if (storeFile == null && envStorePath != null) {
            val envStore = rootProject.file(envStorePath)
            if (envStore.exists()) {
                storeFile = envStore
            }
        }

        if (storePassword.isNullOrEmpty()) {
            storePassword = env["ANDROID_KEYSTORE_PASSWORD"]
        }
        if (keyAlias.isNullOrEmpty()) {
            keyAlias = env["ANDROID_KEY_ALIAS"]
        }
        if (keyPassword.isNullOrEmpty()) {
            keyPassword = env["ANDROID_KEY_PASSWORD"]
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true          // ← 코드 축소 ON (R8)
            isShrinkResources = true        // ← 리소스 축소 ON
            signingConfig = if (releaseSigning.storeFile != null) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // (선택) 패키징 충돌 방지
    packaging {
        resources {
            excludes += setOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1"
            )
        }
    }

    // (선택) Lint 설정
    lint {
        abortOnError = false
    }
}

// Flutter 모듈 소스 경로
flutter {
    source = "../.."
}

dependencies {
    // AndroidX 최신 정렬 (lStar 리소스 관련 링크 실패 예방에 도움)
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.13.0")

    // JDK API desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
