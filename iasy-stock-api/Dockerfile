# Dockerfile para IasyStock Backend API
# Optimizado para Coolify deployment

# ==========================================
# Stage 1: Build
# ==========================================
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml primero para aprovechar cache de layers
COPY pom.xml .

# Descargar dependencias (se cachea si pom.xml no cambia)
RUN mvn dependency:go-offline -B

# Copy código fuente
COPY src ./src

# Compilar y empaquetar (skip tests para build más rápido)
RUN mvn clean package -DskipTests -B

# ==========================================
# Stage 2: Runtime
# ==========================================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Instalar curl para health checks
RUN apk add --no-cache curl

# Crear usuario no-root para seguridad
RUN addgroup -S iasystock && adduser -S iasystock -G iasystock

# Copiar JAR del stage de build
COPY --from=build /app/target/*.jar app.jar

# Cambiar ownership
RUN chown iasystock:iasystock app.jar

# Usar usuario no-root
USER iasystock

# Exponer puerto
EXPOSE 8089

# Variables de entorno por defecto (se sobreescriben en Coolify)
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-Xms512m -Xmx1024m"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8089/actuator/health || exit 1

# Ejecutar aplicación
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
