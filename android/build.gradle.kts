buildscript {
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 36e272d (Updated project files 2)
    repositories {
        google()
        mavenCentral()
    }
<<<<<<< HEAD
=======
>>>>>>> 8ae2a4ecf58c9b20dd7b250d8c409095c181869a
=======
>>>>>>> 36e272d (Updated project files 2)
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
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
