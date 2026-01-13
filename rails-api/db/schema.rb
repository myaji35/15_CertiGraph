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

ActiveRecord::Schema[7.2].define(version: 2026_01_13_225315) do
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

  create_table "exam_answers", force: :cascade do |t|
    t.integer "exam_session_id", null: false
    t.integer "question_id", null: false
    t.string "selected_answer"
    t.boolean "is_correct"
    t.integer "time_spent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_session_id"], name: "index_exam_answers_on_exam_session_id"
    t.index ["question_id"], name: "index_exam_answers_on_question_id"
  end

  create_table "exam_schedules", force: :cascade do |t|
    t.string "certification_code"
    t.string "certification_name"
    t.integer "exam_year"
    t.integer "exam_round"
    t.date "written_exam_date"
    t.date "written_exam_reg_start"
    t.date "written_exam_reg_end"
    t.date "practical_exam_date"
    t.date "practical_exam_reg_start"
    t.date "practical_exam_reg_end"
    t.date "announcement_date"
    t.decimal "exam_fee"
    t.string "exam_location"
    t.json "additional_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exam_sessions", force: :cascade do |t|
    t.integer "study_set_id", null: false
    t.integer "user_id", null: false
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "total_questions"
    t.integer "answered_questions"
    t.integer "correct_answers"
    t.integer "time_limit"
    t.float "score"
    t.string "exam_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["study_set_id"], name: "index_exam_sessions_on_study_set_id"
    t.index ["user_id"], name: "index_exam_sessions_on_user_id"
  end

  create_table "options", force: :cascade do |t|
    t.integer "question_id", null: false
    t.text "content"
    t.boolean "is_correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.integer "study_material_id", null: false
    t.text "content"
    t.text "passage"
    t.text "explanation"
    t.integer "difficulty"
    t.text "embedding_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "options"
    t.string "answer"
    t.string "topic"
    t.integer "question_number"
    t.index ["difficulty"], name: "index_questions_on_difficulty"
    t.index ["study_material_id"], name: "index_questions_on_study_material_id"
    t.index ["topic"], name: "index_questions_on_topic"
  end

  create_table "study_materials", force: :cascade do |t|
    t.integer "study_set_id", null: false
    t.string "name"
    t.string "status"
    t.integer "parsing_progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "extracted_data"
    t.text "error_message"
    t.index ["study_set_id"], name: "index_study_materials_on_study_set_id"
  end

  create_table "study_sets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "description"
    t.date "exam_date"
    t.string "certification"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_study_sets_on_user_id"
  end

  create_table "test_answers", force: :cascade do |t|
    t.integer "test_question_id", null: false
    t.string "selected_answer"
    t.boolean "is_correct"
    t.integer "time_spent"
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["test_question_id"], name: "index_test_answers_on_test_question_id", unique: true
  end

  create_table "test_questions", force: :cascade do |t|
    t.integer "test_session_id", null: false
    t.integer "question_id", null: false
    t.integer "question_number"
    t.json "shuffled_options"
    t.boolean "is_marked", default: false
    t.boolean "is_answered", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_test_questions_on_question_id"
    t.index ["test_session_id", "question_number"], name: "index_test_questions_on_test_session_id_and_question_number"
    t.index ["test_session_id"], name: "index_test_questions_on_test_session_id"
  end

  create_table "test_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_set_id", null: false
    t.string "test_type"
    t.integer "question_count", default: 20
    t.integer "time_limit"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "correct_answers", default: 0
    t.integer "total_answered", default: 0
    t.decimal "score", precision: 5, scale: 2
    t.string "status", default: "in_progress"
    t.json "settings"
    t.json "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_test_sessions_on_status"
    t.index ["study_set_id", "status"], name: "index_test_sessions_on_study_set_id_and_status"
    t.index ["study_set_id"], name: "index_test_sessions_on_study_set_id"
    t.index ["user_id", "status"], name: "index_test_sessions_on_user_id_and_status"
    t.index ["user_id"], name: "index_test_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.string "encrypted_password"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wrong_answers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "question_id", null: false
    t.integer "study_set_id", null: false
    t.string "selected_answer"
    t.integer "attempt_count"
    t.datetime "last_attempted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_wrong_answers_on_question_id"
    t.index ["study_set_id"], name: "index_wrong_answers_on_study_set_id"
    t.index ["user_id"], name: "index_wrong_answers_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "exam_answers", "exam_sessions"
  add_foreign_key "exam_answers", "questions"
  add_foreign_key "exam_sessions", "study_sets"
  add_foreign_key "exam_sessions", "users"
  add_foreign_key "options", "questions"
  add_foreign_key "questions", "study_materials"
  add_foreign_key "study_materials", "study_sets"
  add_foreign_key "study_sets", "users"
  add_foreign_key "test_answers", "test_questions"
  add_foreign_key "test_questions", "questions"
  add_foreign_key "test_questions", "test_sessions"
  add_foreign_key "test_sessions", "study_sets"
  add_foreign_key "test_sessions", "users"
  add_foreign_key "wrong_answers", "questions"
  add_foreign_key "wrong_answers", "study_sets"
  add_foreign_key "wrong_answers", "users"
end
