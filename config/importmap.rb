pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Pin all individual controllers manually
pin "controllers/application", preload: true
pin "controllers/activity_chart_controller", preload: true
pin "controllers/alert_controller", preload: true
pin "controllers/dropdown_controller", preload: true
pin "controllers/flash_controller", preload: true
pin "controllers/hello_controller", preload: true
pin "controllers/metrics_controller", preload: true
pin "controllers/notificaciones_controller", preload: true
pin "controllers/pregunta_form_controller", preload: true
pin "controllers/progreso_charts_controller", preload: true
pin "controllers/quiz_chart_controller", preload: true
pin "controllers/quiz_controller", preload: true
pin "controllers/quiz_form_controller", preload: true
pin "controllers/quiz_preguntas_controller", preload: true
pin "controllers/quiz_response_controller", preload: true
pin "controllers/quiz_timer_controller", preload: true
pin "controllers/terminal_controller", preload: true
pin "controllers/theme_controller", preload: true
pin "controllers/ttyd_controller", preload: true
pin "controllers/wetty_controller", preload: true 
pin "controllers/notifications_controller", preload: true

# Pin all channels
pin_all_from "app/javascript/channels", under: "channels"

# ActionCable
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "channels/consumer", to: "channels/consumer.js"