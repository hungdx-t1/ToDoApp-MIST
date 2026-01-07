// {projectdir}/android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Cú pháp Kotlin DSL dùng ngoặc đơn và ngoặc kép
        classpath("com.android.tools.build:gradle:8.6.0")

        // Bạn cũng nên có Kotlin Plugin ở đây (nếu chưa cấu hình ở chỗ khác)
        // Phiên bản Kotlin nên tương thích (ví dụ 1.9.0 hoặc mới hơn)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
