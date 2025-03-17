FROM ruby:3.3.4

# Instalar dependencias del sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm

# Instalar Yarn
RUN npm install -g yarn

# Crear directorio de la aplicación
WORKDIR /app

# Copiar Gemfile y Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Instalar gemas
RUN bundle install

# Copiar el resto de la aplicación
COPY . .

# Fix encoding issues in JavaScript files
COPY docker_fix_encoding.sh ./
RUN chmod +x ./docker_fix_encoding.sh && ./docker_fix_encoding.sh

# Instalar dependencias de Node.js
RUN yarn install

# Precompilar assets - using a separate script for better error handling
COPY docker_precompile_assets.sh ./
RUN chmod +x ./docker_precompile_assets.sh && ./docker_precompile_assets.sh

# Exponer puerto
EXPOSE 3000

# Configurar punto de entrada
ENTRYPOINT ["./bin/docker-entrypoint"]

# Comando por defecto
CMD ["rails", "server", "-b", "0.0.0.0"]