FROM eclipse-temurin:17-jre
RUN apt-get update && apt-get install -y --no-install-recommends \
    fontconfig \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
# La clé API Gemini est injectée au runtime via GEMINI_API_KEY (secret GitHub).
# Spring Boot lit ${GEMINI_API_KEY} depuis l'environnement du conteneur.
ENTRYPOINT ["java", "-jar", "app.jar"]
