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
  
  desc "Carga el esquema base (tablas iniciales) sin extensiones de Supabase"
  task load_schema: :environment do
    puts "🔄 Cargando esquema base sin extensiones específicas de Supabase..."
    system({ "SCHEMA" => "false" }, "bundle exec rails db:schema:load")
  end
  
  desc "Ejecuta primero las migraciones que crean tablas"
  task run_create_migrations: :environment do
    puts "🔄 Buscando y ejecutando primero las migraciones que crean tablas..."
    
    # Desactivar extensiones de Supabase durante la migración
    ENV['SCHEMA'] = 'false'
    
    # Obtener todas las migraciones pendientes
    pending_migrations = ActiveRecord::Migration.new.migration_context.open.pending_migrations
    
    # Clasificar las migraciones en tres niveles de prioridad
    core_table_migrations = [] # Para tablas fundamentales como usuarios y cursos
    create_table_migrations = [] # Para otras tablas que dependen de las core
    other_migrations = [] # Para modificaciones, índices, etc.
    
    # Lista de tablas que deben crearse primero (orden importante)
    core_tables = ['usuarios', 'cursos']
    
    pending_migrations.each do |migration|
      # Leer el contenido del archivo
      file_path = migration.filename
      content = File.read(file_path)
      
      # Identificar migraciones de tablas principales
      is_core = false
      core_tables.each do |table|
        if content.include?("create_table :#{table}") || content.include?("create_table \"#{table}\"")
          core_table_migrations << migration.version
          is_core = true
          break
        end
      end
      next if is_core
      
      # Identificar otras migraciones de creación de tablas
      if content.include?('create_table')
        create_table_migrations << migration.version
      else
        other_migrations << migration.version
      end
    end
    
    # Ejecutar primero las migraciones con tablas core
    unless core_table_migrations.empty?
      puts "  • Ejecutando #{core_table_migrations.size} migraciones de tablas fundamentales..."
      core_table_migrations.each do |version|
        system({ "SCHEMA" => "false" }, "bundle exec rails db:migrate:up VERSION=#{version}")
      end
    end
    
    # Luego ejecutar otras migraciones que crean tablas
    unless create_table_migrations.empty?
      puts "  • Ejecutando #{create_table_migrations.size} migraciones que crean otras tablas..."
      create_table_migrations.each do |version|
        system({ "SCHEMA" => "false" }, "bundle exec rails db:migrate:up VERSION=#{version}")
      end
    end
    
    # Finalmente ejecutar modificaciones y otros cambios
    unless other_migrations.empty?
      puts "  • Ejecutando #{other_migrations.size} migraciones de modificación de tablas..."
      other_migrations.each do |version|
        system({ "SCHEMA" => "false" }, "bundle exec rails db:migrate:up VERSION=#{version}")
      end
    end
  end
  
  desc "Migra base de datos sin cargar extensiones de Supabase"
  task migrate: :environment do
    puts "🔄 Migrando base de datos compatible con CI..."
    system({ "SCHEMA" => "false" }, "bundle exec rails db:migrate")
  end
  
  desc "Prepara la base de datos para pruebas (estructura + migraciones)"
  task prepare_ci_db: [:db_create, :run_create_migrations] do
    puts "✅ Base de datos preparada para CI"
  end
  
  desc "Lanza tareas CI en secuencia correcta"
  task ci: [:prepare_ci_db, :test] do
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
  
  desc "Reinicia la base de datos de CI desde cero"
  task reset_ci_db: :environment do
    puts "🧹 Eliminando y recreando la base de datos para CI..."
    system({ "SCHEMA" => "false" }, "bundle exec rails db:drop db:create db:schema:load db:migrate")
    puts "✅ Base de datos reiniciada para CI"
  end
end

# Alias para mantener compatibilidad con código existente
namespace :test do
  desc "Ejecuta tests sin extensiones problemáticas de Supabase"
  task safe: ["supabase:test"]
end
