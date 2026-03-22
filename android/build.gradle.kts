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
    
    // Provide flutter properties for plugin compatibility
    if (project.name != "app") {
        project.ext.set("flutter", mapOf(
            "compileSdkVersion" to 35,
            "minSdkVersion" to 21,
            "targetSdkVersion" to 35,
            "ndkVersion" to "27.0.12077973"
        ))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
