// Configure your import map in config/importmap.rb
import "@hotwired/turbo-rails"

// Import all controllers (fallback for stimulus-loading)
import { application } from "./controllers/application"

// Import and register all controllers manually
import ActivityChartController from "./controllers/activity_chart_controller"
application.register("activity-chart", ActivityChartController)

import AlertController from "./controllers/alert_controller"
application.register("alert", AlertController)

import DropdownController from "./controllers/dropdown_controller"
application.register("dropdown", DropdownController)

import FlashController from "./controllers/flash_controller"
application.register("flash", FlashController)

import HelloController from "./controllers/hello_controller"
application.register("hello", HelloController)

import MetricsController from "./controllers/metrics_controller"
application.register("metrics", MetricsController)

import NotificacionesController from "./controllers/notificaciones_controller"
application.register("notificaciones", NotificacionesController)

import PreguntaFormController from "./controllers/pregunta_form_controller"
application.register("pregunta-form", PreguntaFormController)

import ProgresoChartsController from "./controllers/progreso_charts_controller"
application.register("progreso-charts", ProgresoChartsController)

import QuizChartController from "./controllers/quiz_chart_controller"
application.register("quiz-chart", QuizChartController)

import QuizController from "./controllers/quiz_controller"
application.register("quiz", QuizController)

import QuizFormController from "./controllers/quiz_form_controller"
application.register("quiz-form", QuizFormController)

import QuizPreguntasController from "./controllers/quiz_preguntas_controller"
application.register("quiz-preguntas", QuizPreguntasController)

import QuizResponseController from "./controllers/quiz_response_controller"
application.register("quiz-response", QuizResponseController)

import QuizTimerController from "./controllers/quiz_timer_controller"
application.register("quiz-timer", QuizTimerController)

import TerminalController from "./controllers/terminal_controller"
application.register("terminal", TerminalController)

import ThemeController from "./controllers/theme_controller"
application.register("theme", ThemeController)

import WettyController from "./controllers/wetty_controller"
application.register("wetty", WettyController)

import TTYDController from "./controllers/ttyd_controller"
application.register("ttyd", TTYDController)