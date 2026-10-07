# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jdk-alpine@sha256:0bfc69a4758a86710e5c474032d28400a8bd00874766f9e8b1642ac2fd293159 AS build
WORKDIR /workspace
COPY application/ ./
RUN --mount=type=cache,target=/root/.gradle ./gradlew --no-daemon :ingestion-service:bootJar :suggestion-service:bootJar

FROM eclipse-temurin:21-jre-alpine@sha256:51ab5e3302e7141ce665ca3ea85e8b5cd648eafbc3c0c90dd79d6537684e4555
LABEL org.opencontainers.image.source="https://github.com/vimalyad/devops-heros"
ARG SERVICE=ingestion-service
ARG VERSION=local
ENV APP_VERSION=$VERSION
ENV JAVA_TOOL_OPTIONS="-Xms64m -Xmx192m -XX:MaxMetaspaceSize=160m -XX:ReservedCodeCacheSize=48m -XX:MaxDirectMemorySize=64m -XX:ActiveProcessorCount=2"
WORKDIR /app
COPY --from=build /workspace/${SERVICE}/build/libs/${SERVICE}-0.1.0.jar /app/app.jar
USER 65532:65532
EXPOSE 8081 8082
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
