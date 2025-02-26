namespace :db do
  namespace :test do
    desc "Prepare test database (sin esquema si SCHEMA=false)"
    task :prepare_safe => :environment do
      skip_schema = ENV['SCHEMA'] == 'false'
      
      if skip_schema
        puts " Preparando base de datos de prueba sin cargar esquema completo..."
        # Solo crear tablas básicas, saltar extensiones personalizadas
        Rake::Task['db:test:prepare_migrations_only'].invoke
      else
        puts " Preparando base de datos de prueba con esquema completo..."
        # Método estándar
        Rake::Task['db:test:prepare'].invoke
      end
    end

    desc "Prepare test database only with migrations, skipping schema load"
    task :prepare_migrations_only => :environment do
      begin
        # Asegurarse que existe la base de datos
        Rake::Task['db:test:load_structure'].invoke
      rescue
        puts " Estructura no disponible, usando enfoque alternativo..."
        # Si no hay estructura, ejecutar migraciones directamente
        Rake::Task['db:test:load_schema'].invoke
      end
    end
  end
end

namespace :test do
  desc "Run tests with schema safety for Supabase extensions"
  task :safe => :environment do
    ENV['SCHEMA'] = 'false'
    Rake::Task['db:test:prepare_safe'].invoke
    Rake::Task['test'].invoke
  end
end

namespace :supabase do
  desc "Ejecuta pruebas saltando extensiones específicas de Supabase"
  task test: :environment do
    puts "🧪 Ejecutando pruebas omitiendo extensiones de Supabase..."
    ENV['SCHEMA'] = 'false'
    Rake::Task["test"].invoke
  end
  
  desc "Crea base de datos sin cargar extensiones de Supabase"
  task db_create: :environment do
    puts "🔄 Creando base de datos compatible con CI..."
    system({ "SCHEMA" => "false" }, "bundle exec rails db:create")
  end
  
  desc "Migra base de datos sin cargar extensiones de Supabase"
  task migrate: :environment do
    puts "🔄 Migrando base de datos compatible con CI..."
    system({ "SCHEMA" => "false" }, "bundle exec rails db:migrate")
  end
  
  desc "Lanza tareas CI en secuencia correcta"
  task ci: [:db_create, :migrate, :test] do
    puts "✅ CI completado con éxito"
  end
  
  desc "Ayuda para solucionar problemas con extensiones de Supabase"
  task help: :environment do
    puts <<~HELP
      ╔════════════════════════════════════════════════════╗
      ║               AYUDA PARA SUPABASE                  ║
      ╚════════════════════════════════════════════════════╝
      
      Si tienes problemas con extensiones como 'pg_graphql':
      
      1. Para ejecutar pruebas sin extensiones de Supabase:
         $ SCHEMA=false bundle exec rails test
         $ bundle exec rake supabase:test
      
      2. Para crear base de datos sin extensiones:
         $ SCHEMA=false bundle exec rails db:create
         $ bundle exec rake supabase:db_create
         
      3. Para migrar base de datos sin extensiones:
         $ SCHEMA=false bundle exec rails db:migrate
         $ bundle exec rake supabase:migrate
         
      4. Para ejecutar todo el flujo de CI:
         $ bundle exec rake supabase:ci
         
      5. Para CI/GitHub Actions:
         Usa 'postgres:13' como imagen
         y establece SCHEMA=false en tus comandos
         
      Para más información, consulta:
      docs/SUPABASE.md
    HELP
  end
end

# Alias para mantener compatibilidad con código existente
namespace :test do
  desc "Ejecuta tests sin extensiones problemáticas de Supabase"
  task safe: ["supabase:test"]
end
