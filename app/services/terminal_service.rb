# app/services/terminal_service.rb
class TerminalService
  def self.iniciar_sesion(sesion_laboratorio)
    # Configuración inicial del contenedor
    container = DockerContainer.create(
      image: 'kali-training',
      user: sesion_laboratorio.usuario.nombre_usuario,
      session_id: sesion_laboratorio.id
    )
    
    # Configuración de herramientas específicas
    setup_tools(container)
    
    container
  end

  def self.setup_tools(container)
    # Instalación y configuración de herramientas necesarias
    tools = ['nmap', 'wireshark', 'metasploit-framework', 'hydra']
    container.install_tools(tools)
  end
end