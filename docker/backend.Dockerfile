# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jdk-alpine@sha256:0bfc69a4758a86710e5c474032d28400a8bd00874766f9e8b1642ac2fd293159 AS build
WORKDIR /workspace
COPY application/ ./
RUN --mount=type=cache,target=/root/.gradle ./gradlew --no-daemon :ingestion-service:bootJar :suggestion-service:bootJar

FROM gcr.io/distroless/java21-debian13:nonroot@sha256:0a1f5a75661918de9c0813f287f651c3bf2d6dd752eada5f084eb0c1f14ced9e
ARG SERVICE=ingestion-service
ARG VERSION=local
ENV APP_VERSION=$VERSION
ENV JAVA_TOOL_OPTIONS="-Xms64m -Xmx192m -XX:MaxMetaspaceSize=160m -XX:ReservedCodeCacheSize=48m -XX:MaxDirectMemorySize=64m -XX:ActiveProcessorCount=2"
WORKDIR /app
COPY --from=build /workspace/${SERVICE}/build/libs/${SERVICE}-0.1.0.jar /app/app.jar
USER 65532:65532
EXPOSE 8081 8082
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
