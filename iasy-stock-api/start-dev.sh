#!/bin/bash

# Script para iniciar el backend en modo desarrollo
# Carga variables de entorno desde .env y ejecuta Spring Boot

set -e

echo "🚀 Iniciando IasyStock API en modo desarrollo..."

# Verificar si existe el archivo .env
if [ ! -f .env ]; then
  echo "❌ ERROR: No se encontró el archivo .env"
  echo "📝 Por favor, copia .env.example a .env y configura tus valores:"
  echo "   cp .env.example .env"
  echo "   # Edita .env y agrega tu OPENAI_API_KEY"
  exit 1
fi

# Cargar variables de entorno desde .env
echo "📦 Cargando variables de entorno desde .env..."
export $(grep -v '^#' .env | grep -v '^$' | xargs)

# Verificar que OPENAI_API_KEY esté configurado
if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "sk-your-openai-api-key-here" ]; then
  echo "⚠️  ADVERTENCIA: OPENAI_API_KEY no está configurado correctamente en .env"
  echo "   Las funciones de reconocimiento de productos no funcionarán."
  echo ""
  read -p "¿Deseas continuar de todas formas? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Ejecutar el backend con perfil dev
echo "🏃 Ejecutando backend con perfil 'dev'..."
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
