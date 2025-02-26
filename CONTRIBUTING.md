# Guía de Contribución

¡Gracias por tu interés en contribuir a la Plataforma de Ciberseguridad UBB-CSA! Esta guía te ayudará a configurar el entorno de desarrollo y entender nuestro flujo de trabajo.

## Configuración del entorno de desarrollo

1. **Clonar el repositorio**
   ```
   git clone https://github.com/tu-usuario/ciberseguridad_mvp.git
   cd ciberseguridad_mvp
   ```

2. **Instalar dependencias**
   ```
   bundle install
   npm install
   ```

3. **Configurar variables de entorno**
   ```
   cp env.sample .env
   # Editar .env con tus configuraciones
   ```

4. **Configurar la base de datos**
   ```
   rails db:create
   rails db:migrate
   rails db:seed
   ```

5. **Iniciar los servicios**
   ```
   docker-compose up -d
   rails s
   ```

## Estándares de código

### Ruby
- Seguimos la [guía de estilo de Ruby](https://rubystyle.guide/)
- Usamos RuboCop para el linting

### JavaScript
- Seguimos la guía de estilo de StandardJS
- Usamos ESLint para el linting

### CSS/Tailwind
- Organizamos las clases de Tailwind siguiendo el patrón: layout, dimensiones, espaciado, tipografía, colores, miscelánea

## Flujo de trabajo de Git

1. **Crear una rama para tu característica**
   ```
   git checkout -b feature/nombre-descriptivo
   ```

2. **Realizar cambios y hacer commits**
   ```
   git add .
   git commit -m "Descripción clara del cambio"
   ```

3. **Mantente actualizado con la rama principal**
   ```
   git pull origin main
   ```

4. **Resolver cualquier conflicto que pueda surgir**

5. **Subir tus cambios**
   ```
   git push origin feature/nombre-descriptivo
   ```

6. **Crear un Pull Request**
   - Asegúrate de incluir una descripción clara
   - Referencia cualquier issue relacionado

## Pruebas

- Escribe pruebas para tus nuevas características
- Ejecuta la suite de pruebas antes de enviar un PR
  ```
  rails test
  rspec
  ```

## Documentación

- Actualiza la documentación cuando sea necesario
- Utiliza comentarios claros en el código
- Mantén actualizado el README

## Reportar problemas

Si encuentras un bug o tienes una sugerencia de mejora:

1. Revisa las issues existentes para evitar duplicados
2. Usa el template proporcionado para crear una nueva issue
3. Incluye pasos para reproducir el problema y capturas de pantalla si es posible

---

Agradecemos todas las contribuciones, desde correcciones de código hasta mejoras de documentación.

¡Gracias por ayudar a mejorar la Plataforma de Ciberseguridad UBB-CSA!
