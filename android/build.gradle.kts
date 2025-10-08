import com.android.build.gradle.LibraryExtension
import org.gradle.api.tasks.compile.JavaCompile

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
}

// ---- (선택) build 디렉토리 통합 ----
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
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
project(":isar_flutter_libs") {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            namespace = "dev.isar.isar_flutter_libs"
        }
    }
}
