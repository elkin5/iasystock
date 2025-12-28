# 📦 Backend para IasyStock – Sistema Inteligente de Inventarios
**IasyStock** es una aplicación móvil que optimiza la gestión de inventarios mediante el reconocimiento de imágenes (productos, etiquetas, facturas) y el uso de inteligencia artificial para generar reportes a través de lenguaje natural. Está diseñada para pequeños y medianos negocios que desean simplificar y automatizar sus procesos de control de stock.
## 🧠 Características Principales
- 📷 Reconocimiento automático de productos mediante cámara (facturas, etiquetas, producto físico).
- 🤖 Chatbot inteligente para consultar datos e informes.
- 🧾 Registro de entradas y salidas de productos.
- 📊 Control de inventario bajo, vencimiento de productos y promociones activas.
- 📍 Soporte multi-almacén.
- 🧑 Gestión de usuarios, roles y permisos.

## 🚀 Tecnologías Utilizadas
| Componente | Tecnología |
|-----------|------------|
| Frontend  | Flutter |
| Backend   | Kotlin (Spring Boot) |
| Base de Datos | PostgreSQL |
| IA        | OpenAI API |
| Infraestructura | Docker, Railway |
| Autenticación | JWT |

## 📲 Requisitos de instalación y ejecución local
- Flutter SDK
- Docker & Docker Compose
- PostgreSQL
- Java 17 o superior
- API Key de OpenAI

## 📁 Estructura del Proyecto en el backend
```
iasy-stock-api/
├── .idea/                         # Configuración del IDE
├── .mvn/                          # Archivos de Maven Wrapper
├── Database/
│   └── scripts/
│       ├── DDL.sql                # Definición de esquema de base de datos
│       └── initial.sql            # Datos iniciales
├── docs/
│   └── db.md                      # Documentación del modelo de datos
├── img/
│   └── MER.png                    # Diagrama del modelo entidad-relación
├── src/
│   └── main/
│       ├── kotlin/
│       │   └── com.co.kinsoft.api.iasy_stock_api/
│       │       ├── config/        # Configuraciones generales
│       │       ├── domain/        # Lógica de dominio
│       │       └── infraestructure/ # Adaptadores y entrada/salida
│       └── resources/             # Archivos de configuración y propiedades
├── test/                          # Pruebas unitarias y de integración
├── target/                        # Archivos compilados (build)
├── .gitignore                     # Archivos ignorados por Git
├── compose.yaml                   # Configuración de servicios Docker
├── HELP.md                        # Ayuda o instrucciones adicionales
├── iasy-stock-api.iml             # Archivo de configuración de proyecto IntelliJ
├── LICENSE                        # Licencia del proyecto
├── mvnw / mvnw.cmd                # Scripts de Maven Wrapper
├── pom.xml                        # Dependencias y configuración de Maven
└── README.md                      # Documentación principal del proyecto
```

## 🧾 Documentación Técnica
- [Diagrama de arquitectura](docs/arquitectura.md)
- [Modelo entidad-relación (MER)](docs/bd.md)
- [Casos de uso y flujo de pantallas](docs/casos-uso.md)
- [Documentación API](docs/api.md)

## 🔄 Roadmap
- [x] Registro por imagen de productos
- [x] Chatbot conectado a la base de datos
- [x] Gestión de stock y reportes
- [ ] Módulo de promociones avanzadas
- [ ] Soporte offline en Flutter

## 🤝 Contribuciones
¡Las contribuciones son bienvenidas!
1. Haz un fork del repositorio
2. Crea una nueva rama: `feature/nueva-funcionalidad`
3. Realiza tus cambios
4. Haz un commit: `git commit -m 'feat: nueva funcionalidad'`
5. Abre un Pull Request
## 🛡️ Licencia
Este proyecto está licenciado bajo los términos de la licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.
## 📬 Contacto
Desarrollado por **Kinsoft Developement**  
📧 kinsoft.developement@gmail.com
