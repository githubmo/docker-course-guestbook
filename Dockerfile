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
COPY src ./src
COPY pom.xml .

# --- runtime stage -----
FROM registry.access.redhat.com/hi/openjdk:21.0.11-runtime AS runner
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
USER 1000
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
