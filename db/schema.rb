# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_03_17_063141) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "pgsodium"
  create_schema "pgsodium_masks"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "pgjwt"
  enable_extension "pgsodium"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "curso_estudiantes", force: :cascade do |t|
    t.bigint "curso_id", null: false
    t.bigint "usuario_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["curso_id", "usuario_id"], name: "index_curso_estudiantes_on_curso_id_and_usuario_id", unique: true
    t.index ["curso_id"], name: "index_curso_estudiantes_on_curso_id"
    t.index ["usuario_id"], name: "index_curso_estudiantes_on_usuario_id"
  end

  create_table "cursos", force: :cascade do |t|
    t.string "nombre"
    t.text "descripcion"
    t.bigint "profesor_id"
    t.string "categoria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "codigo"
    t.boolean "activo", default: true
    t.string "periodo"
    t.integer "estado"
    t.index ["codigo"], name: "index_cursos_on_codigo", unique: true
  end

  create_table "ejercicio_completados", force: :cascade do |t|
    t.bigint "ejercicio_id", null: false
    t.bigint "sesion_laboratorio_id", null: false
    t.bigint "usuario_id", null: false
    t.datetime "completado_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ejercicio_id", "sesion_laboratorio_id", "usuario_id"], name: "index_ejercicio_completados_unique", unique: true
    t.index ["ejercicio_id"], name: "index_ejercicio_completados_on_ejercicio_id"
    t.index ["sesion_laboratorio_id"], name: "index_ejercicio_completados_on_sesion_laboratorio_id"
    t.index ["usuario_id"], name: "index_ejercicio_completados_on_usuario_id"
  end

  create_table "ejercicios", force: :cascade do |t|
    t.bigint "laboratorio_id", null: false
    t.string "titulo", null: false
    t.text "descripcion"
    t.string "tipo", null: false
    t.string "nivel_dificultad", default: "intermedio"
    t.jsonb "parametros", default: {}, null: false
    t.boolean "activo", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "puntos", default: 10
    t.boolean "obligatorio", default: true
    t.integer "orden"
    t.text "pista"
    t.index ["laboratorio_id", "titulo"], name: "index_ejercicios_on_laboratorio_id_and_titulo", unique: true
    t.index ["laboratorio_id"], name: "index_ejercicios_on_laboratorio_id"
    t.index ["tipo"], name: "index_ejercicios_on_tipo"
  end

  create_table "eventos_intento", force: :cascade do |t|
    t.string "tipo", null: false
    t.bigint "usuario_id", null: false
    t.bigint "intento_quiz_id", null: false
    t.jsonb "detalles", default: {}
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["intento_quiz_id"], name: "index_eventos_intento_on_intento_quiz_id"
    t.index ["timestamp"], name: "index_eventos_intento_on_timestamp"
    t.index ["tipo"], name: "index_eventos_intento_on_tipo"
    t.index ["usuario_id"], name: "index_eventos_intento_on_usuario_id"
  end

  create_table "intentos_quiz", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "usuario_id", null: false
    t.integer "estado", default: 0
    t.decimal "puntaje_total", precision: 5, scale: 2
    t.datetime "iniciado_en"
    t.datetime "finalizado_en"
    t.integer "tiempo_usado"
    t.integer "numero_intento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "has_result", default: false
    t.jsonb "detalles_resultado", default: {}
    t.decimal "puntaje_obtenido", precision: 8, scale: 2
    t.decimal "puntaje_maximo", precision: 8, scale: 2
    t.index ["has_result"], name: "index_intentos_quiz_on_has_result"
    t.index ["quiz_id", "usuario_id", "numero_intento"], name: "idx_on_quiz_id_usuario_id_numero_intento_87beb3aa17", unique: true
    t.index ["quiz_id"], name: "index_intentos_quiz_on_quiz_id"
    t.index ["usuario_id"], name: "index_intentos_quiz_on_usuario_id"
  end

  create_table "laboratorios", force: :cascade do |t|
    t.string "nombre"
    t.text "descripcion"
    t.bigint "curso_id", null: false
    t.string "tipo"
    t.string "estado"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nivel_dificultad"
    t.integer "duracion_estimada"
    t.text "objetivos"
    t.text "requisitos"
    t.boolean "activo", default: true
    t.datetime "fecha"
    t.index ["curso_id"], name: "index_laboratorios_on_curso_id"
  end

  create_table "logros", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.string "tipo", null: false
    t.string "titulo", null: false
    t.text "descripcion"
    t.jsonb "metadatos", default: {}
    t.datetime "otorgado_en", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "visible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id", "tipo", "titulo"], name: "index_logros_on_usuario_id_and_tipo_and_titulo", unique: true
    t.index ["usuario_id"], name: "index_logros_on_usuario_id"
  end

  create_table "metrica_laboratorios", force: :cascade do |t|
    t.bigint "sesion_laboratorio_id", null: false
    t.float "cpu_usage", default: 0.0, null: false
    t.float "memory_usage", default: 0.0, null: false
    t.float "network_usage", default: 0.0, null: false
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "laboratorio_id", null: false
    t.index ["laboratorio_id"], name: "index_metrica_laboratorios_on_laboratorio_id"
    t.index ["sesion_laboratorio_id", "timestamp"], name: "idx_on_sesion_laboratorio_id_timestamp_6cb3ff3dda"
    t.index ["sesion_laboratorio_id"], name: "index_metrica_laboratorios_on_sesion_laboratorio_id"
  end

  create_table "notificaciones", force: :cascade do |t|
    t.bigint "usuario_id", null: false
    t.bigint "actor_id"
    t.string "notificable_type"
    t.bigint "notificable_id"
    t.integer "tipo", default: 0, null: false
    t.integer "nivel", default: 0, null: false
    t.string "titulo", null: false
    t.text "contenido", null: false
    t.boolean "leida", default: false
    t.datetime "leida_en"
    t.jsonb "datos_adicionales", default: {}
    t.boolean "mostrar_web", default: true
    t.boolean "mostrar_email", default: false
    t.boolean "mostrar_movil", default: true
    t.string "accion_url"
    t.string "icono"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notificaciones_on_actor_id"
    t.index ["notificable_type", "notificable_id"], name: "index_notificaciones_on_notificable"
    t.index ["notificable_type", "notificable_id"], name: "index_notificaciones_on_notificable_type_and_notificable_id"
    t.index ["usuario_id", "leida"], name: "index_notificaciones_on_usuario_id_and_leida"
    t.index ["usuario_id"], name: "index_notificaciones_on_usuario_id"
  end

  create_table "preferencias_notificaciones", id: :serial, force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.boolean "email_habilitado", default: true
    t.boolean "web_habilitado", default: true
    t.boolean "movil_habilitado", default: true
    t.jsonb "configuracion_tipos", default: {}
    t.boolean "resumen_diario", default: false
    t.boolean "resumen_semanal", default: true
    t.string "hora_resumen", default: "08:00"
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.index ["usuario_id"], name: "index_preferencias_notificaciones_on_usuario_id", unique: true
  end

  create_table "quiz_opciones", force: :cascade do |t|
    t.bigint "pregunta_id", null: false
    t.text "contenido", null: false
    t.boolean "es_correcta", default: false
    t.integer "orden"
    t.boolean "activa", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "par_relacionado", default: {}, null: false
    t.boolean "es_termino", default: false, null: false
    t.index ["pregunta_id", "orden"], name: "index_quiz_opciones_on_pregunta_id_and_orden"
    t.index ["pregunta_id"], name: "index_quiz_opciones_on_pregunta_id"
  end

  create_table "quiz_preguntas", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.text "contenido", null: false
    t.integer "tipo", null: false
    t.decimal "puntaje", precision: 5, scale: 2, null: false
    t.integer "orden"
    t.boolean "activa", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "retroalimentacion"
    t.string "respuesta_correcta"
    t.jsonb "metadata", default: {}
    t.index ["quiz_id", "orden"], name: "index_quiz_preguntas_on_quiz_id_and_orden"
    t.index ["quiz_id"], name: "index_quiz_preguntas_on_quiz_id"
  end

  create_table "quiz_results", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "usuario_id", null: false
    t.bigint "intento_quiz_id", null: false
    t.decimal "puntaje_total", precision: 5, scale: 2, null: false
    t.integer "total_preguntas", null: false
    t.integer "respuestas_correctas", null: false
    t.integer "tiempo_segundos"
    t.jsonb "preguntas_correctas", default: []
    t.jsonb "preguntas_incorrectas", default: []
    t.boolean "aprobado", default: false
    t.integer "posicion_ranking"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["intento_quiz_id"], name: "index_quiz_results_on_intento_quiz_id"
    t.index ["quiz_id", "usuario_id", "intento_quiz_id"], name: "index_quiz_results_on_unique_attempt", unique: true
    t.index ["quiz_id"], name: "index_quiz_results_on_quiz_id"
    t.index ["usuario_id"], name: "index_quiz_results_on_usuario_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "titulo", null: false
    t.text "descripcion"
    t.bigint "curso_id", null: false
    t.bigint "laboratorio_id", null: false
    t.bigint "usuario_id", null: false
    t.integer "estado", default: 0
    t.integer "tiempo_limite"
    t.integer "intentos_permitidos", default: 1
    t.boolean "activo", default: true
    t.datetime "fecha_inicio"
    t.datetime "fecha_fin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "codigo_acceso", comment: "Código único para acceso al quiz"
    t.datetime "fecha_publicacion", comment: "Fecha cuando el quiz fue publicado"
    t.boolean "mostrar_resultados_inmediatos", default: false, comment: "Indica si los resultados se muestran inmediatamente después de finalizar"
    t.boolean "aleatorizar_preguntas", default: false, comment: "Indica si las preguntas se muestran en orden aleatorio"
    t.boolean "aleatorizar_opciones", default: false, comment: "Indica si las opciones de las preguntas se muestran en orden aleatorio"
    t.decimal "peso_calificacion", precision: 5, scale: 2, default: "100.0", comment: "Peso porcentual del quiz en la calificación"
    t.text "instrucciones", comment: "Instrucciones detalladas para los estudiantes"
    t.boolean "has_results_cache", default: false
    t.index ["codigo_acceso"], name: "index_quizzes_on_codigo_acceso", unique: true
    t.index ["curso_id", "laboratorio_id", "titulo"], name: "index_quizzes_on_curso_id_and_laboratorio_id_and_titulo", unique: true
    t.index ["curso_id"], name: "index_quizzes_on_curso_id"
    t.index ["laboratorio_id"], name: "index_quizzes_on_laboratorio_id"
    t.index ["usuario_id"], name: "index_quizzes_on_usuario_id"
  end

  create_table "respuestas_quiz", force: :cascade do |t|
    t.bigint "intento_quiz_id", null: false
    t.bigint "pregunta_id", null: false
    t.bigint "opcion_id"
    t.text "respuesta_texto"
    t.decimal "puntaje_obtenido", precision: 5, scale: 2
    t.boolean "es_correcta"
    t.datetime "respondido_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "datos_json", default: {}, null: false
    t.index ["intento_quiz_id", "pregunta_id"], name: "index_respuestas_quiz_on_intento_quiz_id_and_pregunta_id", unique: true
    t.index ["intento_quiz_id"], name: "index_respuestas_quiz_on_intento_quiz_id"
    t.index ["opcion_id"], name: "index_respuestas_quiz_on_opcion_id"
    t.index ["pregunta_id"], name: "index_respuestas_quiz_on_pregunta_id"
  end

  create_table "sesion_laboratorios", force: :cascade do |t|
    t.bigint "laboratorio_id", null: false
    t.bigint "usuario_id", null: false
    t.string "estado"
    t.datetime "tiempo_inicio"
    t.datetime "tiempo_fin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notas"
    t.json "resultados"
    t.integer "puntuacion"
    t.string "container_id"
    t.boolean "backup_enabled", default: false
    t.datetime "last_backup_at"
    t.jsonb "resource_usage"
    t.string "container_status"
    t.boolean "completado", default: false
    t.index ["container_id"], name: "index_sesion_laboratorios_on_container_id"
    t.index ["laboratorio_id", "usuario_id"], name: "index_sesion_laboratorios_on_laboratorio_id_and_usuario_id"
  end

  create_table "test_quiz_emparejamientos", force: :cascade do |t|
    t.string "nombre", null: false
    t.text "descripcion"
    t.jsonb "configuracion", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "nombre_completo"
    t.string "nombre_usuario"
    t.string "rol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["reset_password_token"], name: "index_usuarios_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "curso_estudiantes", "cursos"
  add_foreign_key "curso_estudiantes", "usuarios"
  add_foreign_key "cursos", "usuarios", column: "profesor_id"
  add_foreign_key "ejercicio_completados", "ejercicios"
  add_foreign_key "ejercicio_completados", "sesion_laboratorios"
  add_foreign_key "ejercicio_completados", "usuarios"
  add_foreign_key "ejercicios", "laboratorios"
  add_foreign_key "eventos_intento", "intentos_quiz"
  add_foreign_key "eventos_intento", "usuarios"
  add_foreign_key "intentos_quiz", "quizzes"
  add_foreign_key "intentos_quiz", "usuarios"
  add_foreign_key "laboratorios", "cursos"
  add_foreign_key "logros", "usuarios"
  add_foreign_key "metrica_laboratorios", "laboratorios"
  add_foreign_key "metrica_laboratorios", "sesion_laboratorios"
  add_foreign_key "notificaciones", "usuarios"
  add_foreign_key "notificaciones", "usuarios", column: "actor_id"
  add_foreign_key "preferencias_notificaciones", "usuarios", name: "fk_rails_usuario"
  add_foreign_key "quiz_opciones", "quiz_preguntas", column: "pregunta_id"
  add_foreign_key "quiz_preguntas", "quizzes"
  add_foreign_key "quiz_results", "intentos_quiz"
  add_foreign_key "quiz_results", "quizzes"
  add_foreign_key "quiz_results", "usuarios"
  add_foreign_key "quizzes", "cursos"
  add_foreign_key "quizzes", "laboratorios"
  add_foreign_key "quizzes", "usuarios"
  add_foreign_key "respuestas_quiz", "intentos_quiz"
  add_foreign_key "respuestas_quiz", "quiz_opciones", column: "opcion_id"
  add_foreign_key "respuestas_quiz", "quiz_preguntas", column: "pregunta_id"
  add_foreign_key "sesion_laboratorios", "laboratorios"
  add_foreign_key "sesion_laboratorios", "usuarios"
end
