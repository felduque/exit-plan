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

// Workaround for Flutter 3.44 built-in Kotlin vs. file_picker 11.
//
// Flutter decides whether to apply `kotlin-android` to a plugin by grepping the
// plugin's build.gradle for a KGP apply line. file_picker's file contains one
// inside an `if (!isAgp9OrAbove)` branch, so Flutter sees a match and skips —
// while file_picker itself skips it too on AGP 9. Nobody applies KGP, its Kotlin
// sources never compile, and the generated plugin registrant then fails with
// "cannot find symbol FilePickerPlugin". Applying it here closes the gap.
// Remove once file_picker ships a build file without that dead branch.
subprojects {
    if (name == "file_picker") {
        pluginManager.apply("kotlin-android")
        // Its compileOptions pin Java to 17, so Kotlin has to match.
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java)
            .configureEach {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
