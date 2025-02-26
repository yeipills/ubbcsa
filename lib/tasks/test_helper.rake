namespace :db do
  namespace :test do
    desc "Prepare test database (sin esquema si SCHEMA=false)"
    task :prepare_safe => :environment do
      skip_schema = ENV['SCHEMA'] == 'false'
      
      if skip_schema
        puts "🔄 Preparando base de datos de prueba sin cargar esquema completo..."
        # Solo crear tablas básicas, saltar extensiones personalizadas
        Rake::Task['db:test:prepare_migrations_only'].invoke
      else
        puts "🔄 Preparando base de datos de prueba con esquema completo..."
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
        puts "⚠️ Estructura no disponible, usando enfoque alternativo..."
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
