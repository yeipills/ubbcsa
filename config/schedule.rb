# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Configuración de tareas programadas con Whenever
every 1.day, at: '8:00 am' do
  runner 'NotificacionesService.enviar_resumenes'
end

every :sunday, at: '1:00 am' do
  runner 'NotificacionesService.limpiar_notificaciones_antiguas(30)'
end
