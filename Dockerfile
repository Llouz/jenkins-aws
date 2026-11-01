FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/hello-api.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]