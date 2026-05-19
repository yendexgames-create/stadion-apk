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

// Ba’zi muhitlarda eski `appcompat-1.1.0` resurslari AAPT2 bilan muammo berishi mumkin.
// Shuni oldini olish uchun appcompat’ni yangiroq versiyaga majburlaymiz.
subprojects {
    configurations.all {
        resolutionStrategy.force("androidx.appcompat:appcompat:1.6.1")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
