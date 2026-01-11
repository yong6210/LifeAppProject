import com.android.build.gradle.LibraryExtension
import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// Keep Android build output under the repo build/ directory (Flutter expects this).
buildDir = file("../build")
subprojects {
    buildDir = File(rootProject.buildDir, name)
}

// ---- 전역 리포지토리 ----
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ---- 공통 JVM/코틀린/자바 설정 (Java 8 경고 제거) ----
subprojects {
    // 모든 Java 컴파일러를 17로
    tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
        // Java 8 옵션 경고 숨김(옵션)
        options.compilerArgs.add("-Xlint:-options")
    }
    tasks.withType(KotlinCompile::class.java).configureEach {
        kotlinOptions.jvmTarget = "17"
    }
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

// ---- app 먼저 평가 필요할 때만 사용 ----
subprojects {
    project.evaluationDependsOn(":app")
}

// ---- clean ----
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ---- 외부 모듈 네임스페이스 예시 (있을 때만) ----
subprojects {
    if (project.name == "isar_flutter_libs") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                namespace = "dev.isar.isar_flutter_libs"
                compileSdk = 36
            }
            // Legacy plugin uses API 30; skip the new verify task that fails due to missing attrs.
            tasks.matching { it.name == "verifyReleaseResources" }.configureEach {
                enabled = false
            }
        }
    }
    if (project.name == "flutter_foreground_task") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                namespace = "com.pravera.flutter_foreground_task"
                compileSdk = 36
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
    if (project.name == "health") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
        tasks.withType(KotlinCompile::class.java).configureEach {
            kotlinOptions.jvmTarget = "11"
        }
    }
}
