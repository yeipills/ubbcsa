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

ActiveRecord::Schema[7.1].define(version: 2024_10_18_105807) do
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

  create_table "careers", force: :cascade do |t|
    t.string "nombre", limit: 150, null: false
    t.bigint "university_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "course_progress", force: :cascade do |t|
    t.bigint "enrollment_id"
    t.float "progress_percent"
    t.float "horas_aprendidas", default: 0.0
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.check_constraint "progress_percent >= 0::double precision AND progress_percent <= 100::double precision", name: "course_progress_progress_percent_check"
  end

  create_table "courses", force: :cascade do |t|
    t.string "nombre", limit: 150, null: false
    t.text "descripcion"
    t.bigint "professor_id"
    t.bigint "category_id"
    t.float "rating", default: 0.0
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.index ["category_id"], name: "idx_courses_category_id"
    t.index ["professor_id"], name: "idx_courses_professor_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "course_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.index ["user_id", "course_id"], name: "idx_enrollments_user_course"
  end

  create_table "followers", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "follower_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }

    t.unique_constraint ["user_id", "follower_id"], name: "followers_user_id_follower_id_key"
  end

  create_table "friend_statuses", id: :serial, force: :cascade do |t|
    t.string "status", limit: 50, null: false

    t.unique_constraint ["status"], name: "friend_statuses_status_key"
  end

  create_table "friends", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "friend_id"
    t.integer "status_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }

    t.unique_constraint ["user_id", "friend_id"], name: "friends_user_id_friend_id_key"
  end

  create_table "materials", force: :cascade do |t|
    t.string "titulo", limit: 255, null: false
    t.text "contenido"
    t.bigint "course_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "notifications", force: :cascade do |t|
    t.text "mensaje", null: false
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "professors", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "course_id"
    t.datetime "purchase_date", precision: nil, default: -> { "now()" }
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "roles", force: :cascade do |t|
    t.string "nombre", limit: 50, null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }

    t.unique_constraint ["nombre"], name: "roles_nombre_key"
  end

  create_table "universities", force: :cascade do |t|
    t.string "nombre", limit: 150, null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "users", force: :cascade do |t|
    t.string "nombre_completo", limit: 100, null: false
    t.string "email", limit: 100, null: false
    t.string "user_name", limit: 50, null: false
    t.string "password_digest", limit: 255, null: false
    t.bigint "role_id"
    t.bigint "career_id"
    t.string "provider", limit: 50
    t.string "uid", limit: 50
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "idx_users_email"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_name"], name: "idx_users_username"
    t.unique_constraint ["email"], name: "users_email_key"
    t.unique_constraint ["user_name"], name: "users_user_name_key"
  end

  add_foreign_key "careers", "universities", name: "careers_university_id_fkey", on_delete: :cascade
  add_foreign_key "course_progress", "enrollments", name: "course_progress_enrollment_id_fkey", on_delete: :cascade
  add_foreign_key "courses", "categories", name: "courses_category_id_fkey", on_delete: :restrict
  add_foreign_key "courses", "professors", name: "courses_professor_id_fkey", on_delete: :restrict
  add_foreign_key "enrollments", "courses", name: "enrollments_course_id_fkey", on_delete: :cascade
  add_foreign_key "enrollments", "users", name: "enrollments_user_id_fkey", on_delete: :cascade
  add_foreign_key "followers", "users", column: "follower_id", name: "followers_follower_id_fkey", on_delete: :cascade
  add_foreign_key "followers", "users", name: "followers_user_id_fkey", on_delete: :cascade
  add_foreign_key "friends", "friend_statuses", column: "status_id", name: "friends_status_id_fkey"
  add_foreign_key "friends", "users", column: "friend_id", name: "friends_friend_id_fkey", on_delete: :cascade
  add_foreign_key "friends", "users", name: "friends_user_id_fkey", on_delete: :cascade
  add_foreign_key "materials", "courses", name: "materials_course_id_fkey", on_delete: :cascade
  add_foreign_key "notifications", "users", name: "notifications_user_id_fkey", on_delete: :cascade
  add_foreign_key "professors", "users", name: "professors_user_id_fkey", on_delete: :cascade
  add_foreign_key "purchases", "courses", name: "purchases_course_id_fkey", on_delete: :cascade
  add_foreign_key "purchases", "users", name: "purchases_user_id_fkey", on_delete: :cascade
  add_foreign_key "users", "careers", name: "users_career_id_fkey", on_delete: :nullify
  add_foreign_key "users", "roles", name: "users_role_id_fkey", on_delete: :restrict
end
