plugins {
    id("org.springframework.boot")
    id("io.spring.dependency-management")
}

dependencies {
    implementation(project(":shared"))

    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-jdbc")
    implementation("org.springframework.boot:spring-boot-starter-kafka")
    implementation("io.micrometer:micrometer-registry-prometheus")

    implementation("org.springframework.boot:spring-boot-starter-flyway")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-webmvc-test")

    constraints {
        implementation("at.yawk.lz4:lz4-java:1.11.4") {
            because("CVE-2026-106451: the Kafka client's lz4-java 1.10.1 is flagged HIGH by the dependency gate")
        }
    }
}

// The queries schema is owned here but kept at the repo root so the M1 loader and the
// service apply the exact same migration. Fold it onto the classpath for Flyway.
tasks.named<ProcessResources>("processResources") {
    from("$rootDir/db/migration") { into("db/migration") }
}
