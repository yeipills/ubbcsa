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

## Solución implementada

Para facilitar el desarrollo en entornos que no tienen las extensiones de Supabase, hemos implementado:

1. Un sistema de detección que omite las extensiones problemáticas cuando se establece `SCHEMA=false`
2. Tareas Rake específicas para trabajar con bases de datos sin estas extensiones

## Comandos disponibles

### Para desarrollo local

```bash
# Ver ayuda sobre Supabase
bundle exec rake supabase:help

# Crear base de datos sin extensiones de Supabase
bundle exec rake supabase:db_create

# Migrar base de datos sin extensiones de Supabase
bundle exec rake supabase:migrate

# Ejecutar pruebas sin extensiones de Supabase
bundle exec rake supabase:test
```

### Forma alternativa (usar directamente la variable de entorno)

```bash
# Crear base de datos sin extensiones de Supabase
SCHEMA=false bundle exec rails db:create

# Migrar base de datos sin extensiones de Supabase
SCHEMA=false bundle exec rails db:migrate

# Ejecutar pruebas sin extensiones de Supabase
SCHEMA=false bundle exec rails test
```

## CI/GitHub Actions

El archivo de CI está configurado para establecer automáticamente `SCHEMA=false` y usar las tareas rake específicas para Supabase.

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
- Ejecuta con `SCHEMA=false` o usa nuestras tareas rake: `bundle exec rake supabase:db_create`
- Si el error persiste, puedes intentar modificar manualmente el archivo `db/schema.rb` comentando las líneas que contienen `enable_extension "pg_graphql"` y otras extensiones de Supabase

### Error: "function not available"

Algunas funciones pueden estar disponibles sólo en Supabase.

Solución:
- Condiciona el código para verificar la disponibilidad
- Crea abstracciones para manejar ambos casos
