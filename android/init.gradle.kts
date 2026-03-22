// Gradle init script to provide flutter properties to all subprojects
allprojects {
    ext {
        set("flutter", mapOf(
            "compileSdkVersion" to 34,
            "minSdkVersion" to 21,
            "targetSdkVersion" to 34,
            "ndkVersion" to "26.1.10909125"
        ))
    }
}
