# Plataforma de Ciberseguridad UBB-CSA
    
[![Ruby on Rails](https://img.shields.io/badge/Ruby_on_Rails-7.1.3-red?logo=rubyonrails&style=for-the-badge)](https://rubyonrails.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13-blue?logo=postgresql&style=for-the-badge)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue?logo=docker&style=for-the-badge)](https://www.docker.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
    
Bienvenido a la **Plataforma de Ciberseguridad UBB-CSA**, un sistema educativo integral diseñado para la enseñanza práctica de ciberseguridad mediante laboratorios interactivos y evaluaciones dinámicas.
    
## Descripción
    
**UBB-CSA** es una aplicación web desarrollada con **Ruby on Rails** que ofrece un entorno completo para el aprendizaje de ciberseguridad. El sistema integra terminales web (Wetty) a través de Docker para proporcionar entornos de laboratorio aislados y seguros donde los estudiantes pueden practicar habilidades prácticas de ciberseguridad en tiempo real.
    
## Características
    
- **Gestión de cursos**: Sistema completo de administración de cursos con roles de profesor y estudiante.
- **Laboratorios interactivos**: Entornos de práctica en vivo para diferentes áreas de ciberseguridad (pentesting, forense, redes).
- **Sistema de evaluación**: Quizzes con preguntas y respuestas para evaluar el conocimiento teórico.
- **Dashboard personalizado**: Métricas de rendimiento y seguimiento de progreso para estudiantes y profesores.
- **Entornos aislados**: Contenedores Docker independientes para cada sesión de laboratorio.
- **Métricas en tiempo real**: Seguimiento de uso de recursos (CPU, memoria, red) durante las sesiones de laboratorio.
- **Interfaz moderna**: Diseño responsivo desarrollado con TailwindCSS.
    
---
    
# Instalación y Configuración
    
## Requisitos previos
    
Asegúrate de que tu sistema tenga instalado:
    
```bash
# Actualiza tu sistema
sudo apt update && sudo apt upgrade -y

# Instala dependencias necesarias
sudo apt install -y curl gnupg build-essential libssl-dev libreadline-dev zlib1g-dev libpq-dev docker docker-compose
```
    
## 1. Instalación de Ruby y Rails
    
### Usando RVM (recomendado)
    
```bash
# Instalar claves GPG
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

# Instalar RVM
\curl -sSL https://get.rvm.io | bash -s stable

# Cargar RVM
source ~/.rvm/scripts/rvm

# Instalar Ruby
rvm install 3.3.4
rvm use 3.3.4 --default

# Verificar instalación
ruby -v

# Instalar Bundler
gem install bundler
```
    
## 2. Instalación del proyecto
    
### Paso 1: Clonar el repositorio
    
```bash
git clone https://github.com/tu-usuario/ciberseguridad_mvp.git
cd ciberseguridad_mvp
```
    
### Paso 2: Instalar dependencias
    
```bash
# Instalar gemas
bundle install

# Instalar dependencias de Node.js
npm install
```
    
### Paso 3: Configurar las variables de entorno
    
Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:
    
```bash
# Base de datos
DB_HOST=localhost
DB_PORT=5432
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_NAME=ciberseguridad_dev

# Configuración de Docker 
SIMULAR_DOCKER=false

# Otras configuraciones
RAILS_ENV=development
```
    
### Paso 4: Configurar la base de datos
    
```bash
rails db:create
rails db:migrate
rails db:seed  # Para cargar datos iniciales
```
    
### Paso 5: Iniciar los servicios
    
```bash
# Iniciar contenedores Docker
docker-compose up -d

# Iniciar el servidor Rails
rails server
```
    
Abre tu navegador y navega a `http://localhost:3000`.
    
---
    
## Estructura del sistema
    
El sistema está compuesto por dos componentes principales:

1. **Aplicación Rails**: Maneja la interfaz de usuario, lógica de negocio y persistencia de datos.
2. **Wetty (Web TTY)**: Terminal web que permite a los estudiantes interactuar con entornos virtuales de ciberseguridad.

### Componentes clave

- **Cursos**: Unidades organizativas que contienen laboratorios y evaluaciones.
- **Laboratorios**: Entornos prácticos donde los estudiantes pueden aplicar habilidades.
- **Quizzes**: Evaluaciones teóricas para comprobar conocimientos.
- **Sesiones de laboratorio**: Instancias activas donde los estudiantes trabajan en tiempo real.
- **Métricas**: Sistema de seguimiento de rendimiento y recursos.

---
    
## Uso del sistema
    
### Para estudiantes
    
1. **Inscripción en cursos**: Navega al listado de cursos y únete usando el código proporcionado por tu profesor.
2. **Acceso a laboratorios**: Selecciona un laboratorio y comienza una sesión para acceder al terminal web.
3. **Realización de quizzes**: Responde a las evaluaciones para demostrar tu conocimiento teórico.
4. **Seguimiento de progreso**: Consulta tu dashboard para ver métricas de rendimiento y actividades completadas.
    
### Para profesores
    
1. **Creación de cursos**: Crea nuevos cursos con sus respectivos laboratorios y quizzes.
2. **Gestión de estudiantes**: Administra la lista de participantes en cada curso.
3. **Monitoreo de actividad**: Supervisa el progreso y métricas de tus estudiantes.
4. **Evaluación**: Revisa los resultados de las evaluaciones y el desempeño en laboratorios.
    
---
    
## Entornos de laboratorio
    
El sistema ofrece varios tipos de laboratorios especializados:

- **Pentesting**: Pruebas de penetración y análisis de vulnerabilidades.
- **Forense**: Análisis forense digital y recuperación de evidencias.
- **Redes**: Configuración y análisis de seguridad en redes.

Cada laboratorio se ejecuta en un contenedor Docker aislado con las herramientas necesarias pre-instaladas.
    
---
    
## Desarrollo y contribución
    
Si deseas contribuir a este proyecto:
    
1. Haz un fork del repositorio.
2. Crea una nueva rama (`git checkout -b feature/nueva-caracteristica`).
3. Realiza tus cambios y haz commit (`git commit -m 'Añadir nueva característica'`).
4. Haz push a la rama (`git push origin feature/nueva-caracteristica`).
5. Abre un Pull Request.
    
---
    
## Tecnologías utilizadas
    
### Backend
- **Ruby on Rails**: Framework principal para el desarrollo
- **PostgreSQL**: Sistema de base de datos relacional
- **Action Cable**: Para comunicación en tiempo real
- **Devise**: Sistema de autenticación
- **Pundit**: Para gestión de autorización
- **Docker**: Para contenedores de laboratorio

### Frontend
- **TailwindCSS**: Framework CSS para el diseño de la interfaz
- **Stimulus.js**: Para interacción del lado del cliente
- **Turbo**: Para navegación más rápida
- **Chart.js**: Para visualización de métricas y estadísticas

### DevOps
- **Docker Compose**: Para orquestación de servicios
- **RSpec**: Para pruebas automatizadas
- **CI/CD**: Integración y despliegue continuo
    
---
    
## Licencia
    
Este proyecto está licenciado bajo la **Licencia MIT**. Consulta el archivo LICENSE para obtener más información.
    
---
