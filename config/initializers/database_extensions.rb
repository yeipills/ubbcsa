# Este inicializador gestiona las extensiones de base de datos para diferentes entornos
# Solo habilita extensiones específicas de Supabase cuando se ejecuta en producción o desarrollo con Supabase

# Enfoque más simple y directo para saltear extensiones de Supabase en entornos CI
Rails.configuration.to_prepare do
  if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL' && ENV['SCHEMA'] == 'false'
    # Solo mostramos este mensaje una vez durante la inicialización
    puts "⚠️ Modo de compatibilidad activado: las extensiones específicas de Supabase serán ignoradas"

    # Monkey patch para prevenir errores con extensiones no disponibles
    module ActiveRecord
      module ConnectionAdapters
        module PostgreSQL
          module SchemaStatements
            alias_method :original_enable_extension, :enable_extension
            
            def enable_extension(name, **)
              supabase_extensions = %w[pg_graphql pgjwt pgsodium]
              
              if supabase_extensions.include?(name)
                puts "⚠️ Saltando extensión #{name} (no disponible en este entorno)"
                return
              end
              
              original_enable_extension(name, **)
            end
          end
        end
      end
    end
  end
end

# Solo mostrar mensaje en entorno de desarrollo
if Rails.env.development?
  puts "🔌 Configuración de extensiones de base de datos cargada"
  puts "ℹ️ Para saltar extensiones de Supabase en tests locales, use: SCHEMA=false"
end
