source "https://rubygems.org"

ruby "3.3.4"

# Rails y componentes principales
gem "rails", "~> 7.1.5"
gem "pg"
gem "puma"
gem "bootsnap", require: false

# Autenticación y autorización
gem "devise"
gem "cancancan"

# API y CORS
gem "rack-cors"
gem "jbuilder"

# Frontend
gem "sprockets-rails"
gem "importmap-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "tailwindcss-rails"
gem 'sassc-rails'

# Caché y background jobs
gem "redis"
gem "sidekiq"

group :development, :test do
  gem "debug"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "dotenv-rails"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "web-console"
end