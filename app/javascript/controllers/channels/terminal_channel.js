// app/javascript/controllers/channels/terminal_channel.js
import consumer from "channels/consumer"

export default class TerminalChannel {
  constructor(sessionId, callback) {
    this.sessionId = sessionId
    this.callback = callback
    this.subscription = null
    this.connect()
  }

  connect() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "LaboratorioChannel",
        session_id: this.sessionId,
        type: "terminal"
      },
      {
        connected: () => {
          console.log(`Conectado al canal de terminal para sesin ${this.sessionId}`)
          this.trigger('connected')
        },

        disconnected: () => {
          console.log(`Desconectado del canal de terminal para sesin ${this.sessionId}`)
          this.trigger('disconnected')
        },

        received: (data) => {
          console.log("Recibidos datos de terminal:", data)
          this.trigger('message', data)
        }
      }
    )
  }

  trigger(event, data = {}) {
    if (typeof this.callback === 'function') {
      this.callback({ event, data })
    }
  }

  sendCommand(command) {
    if (this.subscription) {
      this.subscription.perform('execute_command', { command })
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }
}