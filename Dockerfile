# --- build stage ---
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# rarely changed stuff
COPY pom.xml .
RUN mvn -q dependency:go-offline

# changes on every commit
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -q package -DskipTests

# --- dev stage ---
FROM maven:3.9-eclipse-temurin-21 AS dev
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# --- runtime stage -----
FROM registry.access.redhat.com/hi/openjdk:21.0.11-runtime AS runner
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
USER 1000
# Container flips running -> healthy once Spring's actuator answers.
# start-period gives the JVM room to boot before failures count.
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
