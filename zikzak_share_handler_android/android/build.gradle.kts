apply plugin: "com.android.library"
apply plugin: "kotlin-android"

android {
    namespace = "wtf.zikzak.zikzak_share_handler"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_11
        targetCompatibility = JavaVersion.VERSION_1_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    sourceSets {
        main.java.srcDirs += "src/main/kotlin"
    }

    defaultConfig {
        minSdk = 16
        targetSdk = 36
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7")
    implementation("androidx.sharetarget:sharetarget:1.2.0")
}
