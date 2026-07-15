# syntax=docker/dockerfile:1

# One place to pin the Java line. An ARG *before* FROM parameterises the base image:
#   docker build --build-arg JAVA_VERSION=17 .
ARG JAVA_VERSION=21

# ---- Stage 1: build the jar (needs the full JDK + Maven, ~600 MB) ----
FROM maven:3.9-eclipse-temurin-${JAVA_VERSION} AS build
WORKDIR /app
# Copy the pom first so dependency downloads are cached until pom.xml changes.
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
# Cache mount: the Maven repo lives outside the layer, so even a source change
# (which busts this layer) never re-downloads dependencies.
RUN --mount=type=cache,target=/root/.m2 \
    mvn -q -B clean package -DskipTests

# ---- Stage 2: shared runtime (JRE only, no Maven, no source) ----
FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine AS runtime
WORKDIR /app
# curl is only here so the HEALTHCHECK below can probe the app.
RUN apk add --no-cache curl \
 && addgroup -S app && adduser -S app -G app
# Copy the jar already owned by the non-root user (COPY --chown).
COPY --chown=app:app --from=build /app/target/*.jar app.jar
USER app
EXPOSE 8080
# Container flips running -> healthy once Spring's actuator answers.
# start-period gives the JVM room to boot before failures count.
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]

# ---- dev target: runtime + a shell & tools for debugging ----
# Build it explicitly:  docker build --target dev -t svc:dev .
FROM runtime AS dev
USER root
RUN apk add --no-cache bash busybox-extras
USER app

# ---- prod target: the lean image we ship. Adds nothing on top of runtime,
#      and being LAST it is the default target for `docker build .` ----
FROM runtime AS prod
