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

subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        if (android != null && android.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            var pkg: String? = null
            if (manifestFile.exists()) {
                val manifestContent = manifestFile.readText()
                val matchResult = """package=["']([^"']+)["']""".toRegex().find(manifestContent)
                if (matchResult != null) {
                    pkg = matchResult.groupValues[1]
                }
            }
            android.namespace = pkg ?: ("com.example." + project.name.replace("-", "_").replace(" ", "_"))
        }
    }
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

