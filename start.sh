#!/bin/bash

# Iniciar servicio SSH
service ssh start

# Instalar axios para peticiones HTTP si no está instalado
npm list -g axios || npm install -g axios

# Buscar el directorio de instalación de Wetty
WETTY_DIR=$(npm root -g)/wetty
echo "Wetty instalado en: $WETTY_DIR"

# Crear directorio para middleware si no existe
mkdir -p $WETTY_DIR/middleware

# Configurar middleware para autenticación con tokens de Rails
cat > $WETTY_DIR/middleware/auth-middleware.js << 'EOF'
// auth-middleware.js
const axios = require('axios');

// Middleware para autenticación con token
module.exports = async function(req, res, next) {
  const token = req.query.token;
  const containerId = req.query.containerId;
  const username = req.query.username;
  
  console.log(`Petición recibida: token=${token}, containerId=${containerId}, username=${username}`);
  
  // En modo desarrollo, siempre permitimos acceso para facilitar pruebas
  if (process.env.NODE_ENV === 'development') {
    console.log('Modo desarrollo: acceso permitido con usuario por defecto');
    req.username = username || 'kali';
    return next();
  }
  
  // En producción requerimos token
  if (!token || !containerId) {
    return res.status(401).send('Acceso no autorizado: Token o ID de contenedor faltante');
  }
  
  try {
    // Verificar token con Rails
    const railsHost = process.env.RAILS_HOST || 'web';
    const railsPort = process.env.RAILS_PORT || '3000';
    
    console.log(`Verificando token con ${railsHost}:${railsPort}`);
    
    // Intenta comunicarse con la API de Rails de forma más robusta
    let responseData;
    
    try {
      // Primero intentamos POST como estaba originalmente
      console.log(`Intentando POST a http://${railsHost}:${railsPort}/api/terminal/validate_token`);
      const response = await axios.post(`http://${railsHost}:${railsPort}/api/terminal/validate_token`, {
        token: token,
        container_id: containerId,
        username: username
      });
      responseData = response.data;
    } catch (postError) {
      console.error(`Error en POST: ${postError.message}`);
      
      // Si falla POST, intentamos GET como alternativa
      console.log(`Intentando GET a http://${railsHost}:${railsPort}/api/terminal/validate_token?token=${token}&container_id=${containerId}&username=${username}`);
      const response = await axios.get(`http://${railsHost}:${railsPort}/api/terminal/validate_token?token=${token}&containerId=${containerId}&username=${username}`);
      responseData = response.data;
    }
    
    if (responseData && responseData.valid) {
      // Token válido, almacenar datos de usuario para la sesión
      req.username = responseData.username || username || 'kali';
      console.log(`Autenticación exitosa para usuario: ${req.username}`);
      next();
    } else {
      console.error('Token inválido:', responseData);
      // En desarrollo, permitimos acceso incluso con token inválido
      if (process.env.NODE_ENV === 'development') {
        console.log('Modo desarrollo: acceso permitido a pesar de token inválido');
        req.username = username || 'kali';
        next();
      } else {
        res.status(401).send('Acceso no autorizado: Token inválido');
      }
    }
  } catch (error) {
    console.error('Error de autenticación:', error.message);
    // En desarrollo siempre permitimos
    if (process.env.NODE_ENV === 'development') {
      console.log('Modo desarrollo: acceso permitido tras error');
      req.username = username || 'kali';
      next();
    } else {
      res.status(401).send('Error de autenticación');
    }
  }
};
EOF

# Crear archivo de configuración personalizado para Wetty
cat > $WETTY_DIR/config.json << EOF
{
  "port": 3001,
  "host": "0.0.0.0",
  "title": "UBB Cybersecurity Lab",
  "bypasshelmet": true,
  "auth": false,
  "ssl": {
    "key": "/etc/ssl/private/wetty.key",
    "cert": "/etc/ssl/certs/wetty.crt"
  },
  "ssh": {
    "user": "kali",
    "host": "localhost",
    "auth": "password",
    "pass": "kali"
  }
}
EOF

# Crear script para crear usuario dinámicamente
cat > /usr/local/bin/set-user.sh << 'EOF'
#!/bin/bash
if [ -n "$1" ]; then
  # Verificar si el usuario ya existe
  if ! id "$1" &>/dev/null; then
    echo "Creando usuario $1..."
    # Crear usuario y asignar contraseña idéntica al nombre de usuario
    useradd -m -s /bin/bash "$1"
    echo "$1:$1" | chpasswd
    usermod -aG sudo "$1"
    
    # Configuración personalizada
    echo "export PS1='\[\033[01;32m\]\u@cyberlabs\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '" >> /home/$1/.bashrc
    mkdir -p /home/$1/lab_data
    chown -R $1:$1 /home/$1
  fi
  echo "Usuario listo: $1"
else
  echo "Usando usuario por defecto: kali"
fi
EOF
chmod +x /usr/local/bin/set-user.sh

# Configurar variables de entorno
export RAILS_HOST=${RAILS_HOST:-web}
export RAILS_PORT=${RAILS_PORT:-3000}
export NODE_ENV=${NODE_ENV:-development}

echo "Configuración completada. Iniciando Wetty..."
echo "Entorno: NODE_ENV=$NODE_ENV, RAILS_HOST=$RAILS_HOST, RAILS_PORT=$RAILS_PORT"

# Comprobar si se proporciona un nombre de usuario específico
if [ -n "$USERNAME" ]; then
  echo "Configurando usuario específico: $USERNAME"
  # Crear el usuario dinámico si es necesario
  /usr/local/bin/create_dynamic_user.sh "$USERNAME" "$USER_ID" "$SESSION_ID"
  SSH_USER="$USERNAME"
else
  SSH_USER="kali"
fi

# Comprobar conectividad con Rails
echo "Verificando conectividad con Rails (${RAILS_HOST}:${RAILS_PORT})..."
timeout 5 bash -c "until nc -z ${RAILS_HOST} ${RAILS_PORT}; do echo 'Esperando a que Rails esté disponible...'; sleep 1; done" || echo "Advertencia: No se pudo verificar la conectividad con Rails"

# Iniciar Wetty con configuración dinámica de usuario
echo "Iniciando Wetty con usuario: $SSH_USER"
wetty --port 3001 --host 0.0.0.0 --title "UBB Cybersecurity Lab" --ssh-host localhost --ssh-port 22 --ssh-user "$SSH_USER" --base /wetty
