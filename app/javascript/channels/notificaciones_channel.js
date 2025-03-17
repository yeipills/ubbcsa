import consumer from "./consumer"

let notificacionesSubscription = null;

// Funcin para suscribirse al canal de notificaciones
export function subscribeToNotificaciones(usuarioId, callbacks = {}) {
  // Cancelar cualquier suscripcin existente
  if (notificacionesSubscription) {
    notificacionesSubscription.unsubscribe();
  }
  
  // Crear nueva suscripcin
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
        console.log("Nueva notificacin recibida:", data);
        if (callbacks.onReceived) callbacks.onReceived(data);
      },
      
      // Mtodo para marcar una notificacin como leda
      marcarComoLeida(id) {
        this.perform('marcar_como_leida', { id });
      },
      
      // Mtodo para marcar todas las notificaciones como ledas
      marcarTodasComoLeidas() {
        this.perform('marcar_como_leida', { todas: true });
      }
    }
  );
  
  return notificacionesSubscription;
}

// Exportar tambin la suscripcin actual
export { notificacionesSubscription };