# Configuración de Supabase

Este proyecto utiliza Supabase como base de datos en producción. Este documento explica cómo configurar y trabajar con Supabase en diferentes entornos.

## Configuración local con Supabase

### 1. Variables de entorno

Copia el archivo `env.sample` a `.env` y configura las siguientes variables:

```
# Conexión estándar
DB_HOST=db.tu-proyecto.supabase.co
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=tu_password_de_supabase
DB_NAME=postgres

# API de Supabase
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_KEY=tu_api_key
SUPABASE_DB_URL=postgresql://postgres:tu_password@db.tu-proyecto.supabase.co:5432/postgres
```

### 2. Extensiones de PostgreSQL

Supabase incluye extensiones personalizadas como:
- `pg_graphql`
- `pgsodium`
- `pgjwt`

Estas extensiones no están disponibles en entornos de PostgreSQL estándar, lo que puede causar problemas al ejecutar tests o en entornos CI.

## Ejecución de tests

### Tests en entorno local

Para ejecutar tests sin problemas con extensiones de Supabase:

```bash
SCHEMA=false bundle exec rails test
```

O usando la tarea rake personalizada:

```bash
bundle exec rake test:safe
```

### CI/GitHub Actions

Nuestro archivo de CI está configurado para usar:

```yaml
- name: Create database without schema
  run: |
    bundle exec rails db:create
    bundle exec rails db:test:prepare SCHEMA=false
    
- name: Run tests
  run: bundle exec rails test SCHEMA=false
```

## Migraciones y esquema

Al desarrollar migraciones, ten en cuenta que:

1. Debes evitar usar las extensiones específicas de Supabase en migraciones que necesiten ejecutarse en CI
2. Si necesitas usar funcionalidades específicas de Supabase, considera encapsularlas:

```ruby
def up
  if supabase_environment?
    execute("CREATE EXTENSION IF NOT EXISTS pg_graphql;")
  else
    puts "Saltando extensión pg_graphql en entorno no-Supabase"
  end
end

def supabase_environment?
  ENV['SUPABASE_URL'].present? || 
  !(Rails.env.test? && ENV['CI'].present?)
end
```

## Resolución de problemas

### Error: "could not open extension control file"

Este error ocurre cuando el esquema intenta habilitar extensiones de Supabase en un entorno que no las tiene disponibles.

Solución:
- Ejecuta con `SCHEMA=false`
- Usa la imagen Docker de Supabase para desarrollo local

### Error: "function not available"

Algunas funciones pueden estar disponibles sólo en Supabase.

Solución:
- Condiciona el código para verificar la disponibilidad
- Crea abstracciones para manejar ambos casos
