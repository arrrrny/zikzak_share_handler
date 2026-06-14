pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    resolutionStrategy {
        eachPlugin { details ->
            when (details.requested.id.id) {
                "org.jetbrains.kotlin.android" -> {
                    details.useVersion("2.1.0")
                }
            }
        }
    }
}

rootProject.name = "zikzak_share_handler"
