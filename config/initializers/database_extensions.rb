# Este inicializador gestiona las extensiones de base de datos para diferentes entornos
# Solo habilita extensiones específicas de Supabase cuando se ejecuta en producción o desarrollo con Supabase

module ActiveRecord
  module Tasks
    class PostgreSQLDatabaseTasks
      # Override para saltar extensiones no disponibles en CI/Test
      def load_schema_with_extension_safeguarding(format = ActiveRecord.schema_format, file = nil)
        skip_unsafe_extensions = ENV['SCHEMA'] == 'false'
        
        if skip_unsafe_extensions
          puts "⚠️ Saltando carga de extensiones específicas de Supabase (pg_graphql, etc.)"
          
          # Reescribir temporalmente el schema.rb para saltear extensiones problemáticas
          original_schema = File.read(schema_file(format))
          modified_schema = original_schema.dup
          
          # Comentar las extensiones específicas de Supabase
          %w[pg_graphql pgjwt pgsodium].each do |ext|
            modified_schema.gsub!(/^(\s*enable_extension\s+"#{ext}")/, '# \1')
          end
          
          # Escribir schema modificado temporalmente
          temp_schema = Tempfile.new(['schema', '.rb'])
          temp_schema.write(modified_schema)
          temp_schema.close
          
          # Cargar esquema modificado
          load_schema_for(format, temp_schema.path)
          temp_schema.unlink
        else
          # Carga normal del esquema
          load_schema_for(format, file)
        end
      end
      
      alias_method :original_load_schema, :load_schema
      alias_method :load_schema, :load_schema_with_extension_safeguarding
    end
  end
end

# Solo mostrar mensaje en entorno de desarrollo
if Rails.env.development?
  puts "🔌 Configuración de extensiones de base de datos cargada"
  puts "ℹ️ Para saltar extensiones de Supabase en tests locales, use: SCHEMA=false"
end
