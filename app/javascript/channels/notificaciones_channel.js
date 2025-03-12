import consumer from "./consumer"

let notificacionesSubscription = null;

// Función para suscribirse al canal de notificaciones
export function subscribeToNotificaciones(usuarioId, callbacks = {}) {
  // Cancelar cualquier suscripción existente
  if (notificacionesSubscription) {
    notificacionesSubscription.unsubscribe();
  }
  
  // Crear nueva suscripción
  notificacionesSubscription = consumer.subscriptions.create(
    { channel: "NotificacionesChannel", usuario_id: usuarioId },
    {
      connected() {
        console.log("Conectado al canal de notificaciones");
        if (callbacks.onConnected) callbacks.onConnected();
      },
      
      disconnected() {
        console.log("Desconectado del canal de notificaciones");
        if (callbacks.onDisconnected) callbacks.onDisconnected();
      },
      
      received(data) {
        console.log("Nueva notificación recibida:", data);
        if (callbacks.onReceived) callbacks.onReceived(data);
      },
      
      // Método para marcar una notificación como leída
      marcarComoLeida(id) {
        this.perform('marcar_como_leida', { id });
      },
      
      // Método para marcar todas las notificaciones como leídas
      marcarTodasComoLeidas() {
        this.perform('marcar_como_leida', { todas: true });
      }
    }
  );
  
  return notificacionesSubscription;
}

// Exportar también la suscripción actual
export { notificacionesSubscription };