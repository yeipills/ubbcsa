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

ActiveRecord::Schema[7.1].define(version: 2025_02_24_203558) do
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
    t.index ["curso_id"], name: "index_laboratorios_on_curso_id"
  end

  create_table "metrica_laboratorios", force: :cascade do |t|
    t.bigint "sesion_laboratorio_id", null: false
    t.float "cpu_usage", default: 0.0, null: false
    t.float "memory_usage", default: 0.0, null: false
    t.float "network_usage", default: 0.0, null: false
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sesion_laboratorio_id", "timestamp"], name: "idx_on_sesion_laboratorio_id_timestamp_6cb3ff3dda"
    t.index ["sesion_laboratorio_id"], name: "index_metrica_laboratorios_on_sesion_laboratorio_id"
  end

  create_table "quiz_opciones", force: :cascade do |t|
    t.bigint "pregunta_id", null: false
    t.text "contenido", null: false
    t.boolean "es_correcta", default: false
    t.integer "orden"
    t.boolean "activa", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["quiz_id", "orden"], name: "index_quiz_preguntas_on_quiz_id_and_orden"
    t.index ["quiz_id"], name: "index_quiz_preguntas_on_quiz_id"
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
    t.index ["laboratorio_id", "usuario_id"], name: "index_sesion_laboratorios_on_laboratorio_id_and_usuario_id"
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

  add_foreign_key "curso_estudiantes", "cursos"
  add_foreign_key "curso_estudiantes", "usuarios"
  add_foreign_key "cursos", "usuarios", column: "profesor_id"
  add_foreign_key "intentos_quiz", "quizzes"
  add_foreign_key "intentos_quiz", "usuarios"
  add_foreign_key "laboratorios", "cursos"
  add_foreign_key "metrica_laboratorios", "sesion_laboratorios"
  add_foreign_key "quiz_opciones", "quiz_preguntas", column: "pregunta_id"
  add_foreign_key "quiz_preguntas", "quizzes"
  add_foreign_key "quizzes", "cursos"
  add_foreign_key "quizzes", "laboratorios"
  add_foreign_key "quizzes", "usuarios"
  add_foreign_key "respuestas_quiz", "intentos_quiz", column: "intento_quiz_id"
  add_foreign_key "respuestas_quiz", "quiz_opciones", column: "opcion_id"
  add_foreign_key "respuestas_quiz", "quiz_preguntas", column: "pregunta_id"
  add_foreign_key "sesion_laboratorios", "laboratorios"
  add_foreign_key "sesion_laboratorios", "usuarios"
end
