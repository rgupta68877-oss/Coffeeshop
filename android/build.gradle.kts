buildscript {
<<<<<<< HEAD
=======
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 36e272d (Updated project files 2)
=======
>>>>>>> df1b95a (New UI and Fixes)
>>>>>>> 50e1f6c218ce77364ce7d0f3eb166abdb42739f7
    repositories {
        google()
        mavenCentral()
    }
<<<<<<< HEAD
=======
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 8ae2a4ecf58c9b20dd7b250d8c409095c181869a
=======
>>>>>>> 36e272d (Updated project files 2)
=======
>>>>>>> df1b95a (New UI and Fixes)
>>>>>>> 50e1f6c218ce77364ce7d0f3eb166abdb42739f7
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
