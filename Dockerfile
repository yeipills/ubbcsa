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

# Instalar dependencias de Node.js
RUN yarn install

# Precompilar assets
RUN rails assets:precompile

# Exponer puerto
EXPOSE 3000

# Configurar punto de entrada
ENTRYPOINT ["./bin/docker-entrypoint"]

# Comando por defecto
CMD ["rails", "server", "-b", "0.0.0.0"]