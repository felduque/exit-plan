allprojects {
    repositories {
        google()
        mavenCentral()
        // TikTok publishes its Android Business SDK through JitPack only; it is
        // on neither Google nor Maven Central. Without this, the
        // tiktok_events_sdk plugin fails to resolve com.github.bytedance.*.
        maven { url = uri("https://jitpack.io") }
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

// Workaround for Flutter 3.44 built-in Kotlin vs. plugins that guard their KGP
// apply behind an AGP version check.
//
// Flutter decides whether to apply `kotlin-android` to a plugin by grepping the
// plugin's build file for a KGP apply line. Both plugins below contain one
// inside a branch that only runs on AGP 8 or lower (`if (!isAgp9OrAbove)` in
// file_picker 11, `if (agpVersion < 9)` in tiktok_events_sdk 1.3). Flutter sees
// the match and skips — while the plugin itself skips it too on AGP 9. Nobody
// applies KGP, the plugin's Kotlin sources never compile, and the generated
// registrant then fails with "cannot find symbol FilePickerPlugin" /
// "cannot find symbol TiktokEventsSdkPlugin". Applying it here closes the gap.
//
// Drop each name once its plugin ships a build file without that dead branch.
val pluginsMissingKotlin = setOf("file_picker", "tiktok_events_sdk")

subprojects {
    if (name in pluginsMissingKotlin) {
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
