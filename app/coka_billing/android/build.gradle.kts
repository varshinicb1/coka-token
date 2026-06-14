plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Patch flutter_bluetooth_serial's merged values.xml to remove android:lStar reference
// which causes AAPT: error: resource android:attr/lStar not found in newer SDKs
subprojects {
    if (name == "flutter_bluetooth_serial") {
        afterEvaluate {
            tasks.matching { it.name.startsWith("merge") && it.name.endsWith("Resources") }.configureEach {
                doLast {
                    val variant = name.removePrefix("merge").removeSuffix("Resources").lowercase()
                    val valuesFile = project.file("${project.buildDir}/intermediates/merged_res/$variant/${name}/values/values.xml")
                    if (valuesFile.exists()) {
                        val original = valuesFile.readText()
                        val patched = original.replace("<attr name=\"android:lStar\"/>", "")
                        if (patched != original) {
                            valuesFile.writeText(patched)
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
