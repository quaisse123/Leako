FROM amazoncorretto:17-alpine
RUN apk add --no-cache fontconfig ttf-dejavu
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
