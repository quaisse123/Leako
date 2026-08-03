FROM eclipse-temurin:17-jre
RUN apt-get update && apt-get install -y --no-install-recommends \
    fontconfig \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
