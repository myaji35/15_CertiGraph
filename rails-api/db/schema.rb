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

ActiveRecord::Schema[7.2].define(version: 2026_01_15_150001) do
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

  create_table "analysis_results", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "question_id", null: false
    t.integer "study_set_id", null: false
    t.string "analysis_type", null: false
    t.string "status", default: "pending", null: false
    t.float "concept_gap_score", default: 0.0
    t.string "error_type"
    t.text "error_description"
    t.json "related_concepts"
    t.json "prerequisite_concepts"
    t.json "dependent_concepts"
    t.integer "graph_depth", default: 0
    t.integer "nodes_traversed", default: 0
    t.json "traversal_path"
    t.text "llm_reasoning"
    t.json "llm_analysis_metadata"
    t.float "confidence_score", default: 0.0
    t.json "recommended_learning_path"
    t.integer "processing_time_ms", default: 0
    t.text "error_message"
    t.text "error_backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_type", "status"], name: "idx_analysis_results_type_status"
    t.index ["concept_gap_score"], name: "index_analysis_results_on_concept_gap_score"
    t.index ["created_at"], name: "index_analysis_results_on_created_at"
    t.index ["question_id"], name: "index_analysis_results_on_question_id"
    t.index ["study_set_id"], name: "index_analysis_results_on_study_set_id"
    t.index ["user_id", "study_set_id", "status"], name: "idx_analysis_results_user_study_status"
    t.index ["user_id"], name: "index_analysis_results_on_user_id"
  end

  create_table "certifications", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_en"
    t.string "organization", null: false
    t.string "organization_en"
    t.string "category"
    t.string "series"
    t.string "website_url"
    t.text "description"
    t.integer "annual_applicants"
    t.float "pass_rate"
    t.boolean "is_national", default: true
    t.boolean "is_active", default: true
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_certifications_on_category"
    t.index ["is_active"], name: "index_certifications_on_is_active"
    t.index ["name"], name: "index_certifications_on_name"
    t.index ["organization"], name: "index_certifications_on_organization"
  end

  create_table "chunk_questions", force: :cascade do |t|
    t.integer "document_chunk_id", null: false
    t.integer "question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_chunk_id", "question_id"], name: "index_chunk_questions_on_document_chunk_id_and_question_id", unique: true
    t.index ["document_chunk_id"], name: "index_chunk_questions_on_document_chunk_id"
    t.index ["question_id"], name: "index_chunk_questions_on_question_id"
  end

  create_table "document_chunks", force: :cascade do |t|
    t.integer "study_material_id", null: false
    t.text "content", null: false
    t.integer "token_count", default: 0
    t.integer "chunk_index", null: false
    t.integer "start_position", null: false
    t.integer "end_position", null: false
    t.boolean "has_passage", default: false
    t.text "passage_context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["study_material_id", "chunk_index"], name: "index_document_chunks_on_study_material_id_and_chunk_index", unique: true
    t.index ["study_material_id"], name: "index_document_chunks_on_study_material_id"
  end

  create_table "embeddings", force: :cascade do |t|
    t.integer "document_chunk_id", null: false
    t.json "vector", null: false
    t.float "magnitude", null: false
    t.integer "model_version", default: 1
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_chunk_id"], name: "index_embeddings_on_document_chunk_id"
    t.index ["generated_at"], name: "index_embeddings_on_generated_at"
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

  create_table "exam_notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "exam_schedule_id", null: false
    t.string "notification_type", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "sent_at"
    t.string "status", default: "pending"
    t.string "channel"
    t.text "message"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_schedule_id", "notification_type"], name: "index_exam_notif_on_schedule_and_type"
    t.index ["exam_schedule_id"], name: "index_exam_notifications_on_exam_schedule_id"
    t.index ["notification_type"], name: "index_exam_notifications_on_notification_type"
    t.index ["scheduled_at"], name: "index_exam_notifications_on_scheduled_at"
    t.index ["user_id", "status"], name: "index_exam_notifications_on_user_id_and_status"
    t.index ["user_id"], name: "index_exam_notifications_on_user_id"
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
    t.integer "certification_id"
    t.integer "year"
    t.integer "round"
    t.string "exam_type"
    t.date "registration_start_date"
    t.date "registration_end_date"
    t.date "exam_date"
    t.time "exam_time"
    t.date "result_date"
    t.float "pass_rate"
    t.float "cutoff_score"
    t.integer "capacity"
    t.integer "applicants_count"
    t.text "notice"
    t.string "status", default: "scheduled"
    t.json "metadata"
    t.index ["certification_id", "year"], name: "index_exam_schedules_on_certification_id_and_year"
    t.index ["certification_id"], name: "index_exam_schedules_on_certification_id"
    t.index ["exam_date"], name: "index_exam_schedules_on_exam_date"
    t.index ["registration_start_date"], name: "index_exam_schedules_on_registration_start_date"
    t.index ["status"], name: "index_exam_schedules_on_status"
    t.index ["year", "exam_date"], name: "index_exam_schedules_on_year_and_exam_date"
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

  create_table "knowledge_edges", force: :cascade do |t|
    t.integer "knowledge_node_id", null: false
    t.integer "related_node_id"
    t.string "relationship_type", null: false
    t.float "weight", default: 0.5
    t.text "reasoning"
    t.json "metadata", default: {}
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_knowledge_edges_on_active"
    t.index ["knowledge_node_id", "related_node_id"], name: "index_knowledge_edges_on_knowledge_node_id_and_related_node_id", unique: true
    t.index ["knowledge_node_id"], name: "index_knowledge_edges_on_knowledge_node_id"
    t.index ["related_node_id"], name: "index_knowledge_edges_on_related_node_id"
    t.index ["relationship_type", "weight"], name: "index_knowledge_edges_on_relationship_type_and_weight"
    t.index ["relationship_type"], name: "index_knowledge_edges_on_relationship_type"
  end

  create_table "knowledge_nodes", force: :cascade do |t|
    t.integer "study_material_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "level", default: "concept", null: false
    t.string "parent_name"
    t.integer "difficulty", default: 3
    t.integer "importance", default: 3
    t.json "metadata", default: {}
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_knowledge_nodes_on_active"
    t.index ["name"], name: "index_knowledge_nodes_on_name"
    t.index ["parent_name"], name: "index_knowledge_nodes_on_parent_name"
    t.index ["study_material_id", "level"], name: "index_knowledge_nodes_on_study_material_id_and_level"
    t.index ["study_material_id", "parent_name"], name: "index_knowledge_nodes_on_study_material_id_and_parent_name"
    t.index ["study_material_id"], name: "index_knowledge_nodes_on_study_material_id"
  end

  create_table "learning_recommendations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_set_id", null: false
    t.integer "analysis_result_id"
    t.string "recommendation_type", null: false
    t.string "status", default: "pending", null: false
    t.json "recommended_questions"
    t.integer "total_recommended_count", default: 0
    t.integer "priority_level", default: 5
    t.integer "suggested_difficulty"
    t.float "difficulty_adjustment_ratio", default: 1.0
    t.json "weakness_analysis"
    t.json "concept_mastery_map"
    t.json "learning_path"
    t.integer "estimated_learning_hours", default: 0
    t.json "personalization_params"
    t.json "adaptive_params"
    t.float "learning_efficiency_index", default: 0.0
    t.float "success_probability", default: 0.0
    t.float "time_efficiency", default: 0.0
    t.datetime "started_at"
    t.datetime "completed_at"
    t.json "progress_tracking"
    t.text "user_feedback"
    t.boolean "is_accepted", default: false
    t.integer "feedback_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_result_id"], name: "index_learning_recommendations_on_analysis_result_id"
    t.index ["created_at"], name: "index_learning_recommendations_on_created_at"
    t.index ["learning_efficiency_index"], name: "index_learning_recommendations_on_learning_efficiency_index"
    t.index ["priority_level"], name: "index_learning_recommendations_on_priority_level"
    t.index ["recommendation_type", "status"], name: "idx_recommendations_type_status"
    t.index ["study_set_id"], name: "index_learning_recommendations_on_study_set_id"
    t.index ["user_id", "study_set_id", "status"], name: "idx_recommendations_user_study_status"
    t.index ["user_id"], name: "index_learning_recommendations_on_user_id"
  end

  create_table "options", force: :cascade do |t|
    t.integer "question_id", null: false
    t.text "content"
    t.boolean "is_correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "order_id", null: false
    t.string "payment_key"
    t.integer "amount", null: false
    t.string "currency", default: "KRW"
    t.string "status", default: "pending"
    t.string "method"
    t.string "card_company"
    t.string "card_number"
    t.datetime "approved_at"
    t.text "failure_code"
    t.text "failure_message"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
    t.index ["payment_key"], name: "index_payments_on_payment_key"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

# Could not dump table "questions" because of following StandardError
#   Unknown type 'vector' for column 'embedding'


  create_table "solid_queue_batch_jobs", force: :cascade do |t|
    t.integer "batch_id", null: false
    t.integer "job_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_jobs_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_jobs_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "status", default: "enqueued", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_solid_queue_batches_on_status"
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.integer "ready_execution_id", null: false
    t.integer "process_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["process_id", "created_at"], name: "idx_solid_queue_claimed_exec_proc_created"
    t.index ["ready_execution_id"], name: "idx_solid_queue_claimed_exec_ready_exec_id", unique: true
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.integer "job_id", null: false
    t.string "queue_name", null: false
    t.text "exception"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_name", "created_at"], name: "idx_solid_queue_failed_exec_queue_created"
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "class_name", null: false
    t.text "arguments", null: false
    t.integer "executions", default: 0, null: false
    t.string "exception_executions", default: "0", null: false
    t.datetime "finished_at"
    t.string "scheduled_at"
    t.string "locked_at"
    t.string "locked_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_on_queue_name_and_finished_at"
    t.index ["scheduled_at"], name: "index_solid_queue_jobs_on_scheduled_at"
  end

  create_table "solid_queue_paused_jobs", force: :cascade do |t|
    t.integer "job_id", null: false
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_paused_jobs_on_queue_name"
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "last_heartbeat_at"], name: "index_solid_queue_processes_on_kind_and_last_heartbeat_at"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.integer "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.integer "process_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["process_id"], name: "index_solid_queue_ready_executions_on_process_id"
    t.index ["queue_name", "priority"], name: "idx_solid_queue_ready_exec_queue_priority"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.integer "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_name", "scheduled_at"], name: "idx_solid_queue_sched_exec_queue_sched_at"
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

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "payment_id", null: false
    t.string "plan_type", default: "season_pass", null: false
    t.integer "price", null: false
    t.datetime "starts_at", null: false
    t.datetime "expires_at", null: false
    t.boolean "is_active", default: true
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_subscriptions_on_is_active"
    t.index ["payment_id"], name: "index_subscriptions_on_payment_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id", "is_active"], name: "index_subscriptions_on_user_id_and_is_active"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
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

  create_table "user_masteries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "knowledge_node_id", null: false
    t.float "mastery_level", default: 0.0
    t.string "status", default: "untested"
    t.string "color", default: "gray"
    t.integer "attempts", default: 0
    t.integer "correct_attempts", default: 0
    t.integer "last_tested_days_ago"
    t.integer "total_time_minutes", default: 0
    t.datetime "last_tested_at"
    t.json "history", default: []
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color"], name: "index_user_masteries_on_color"
    t.index ["knowledge_node_id"], name: "index_user_masteries_on_knowledge_node_id"
    t.index ["status"], name: "index_user_masteries_on_status"
    t.index ["user_id", "knowledge_node_id"], name: "index_user_masteries_on_user_id_and_knowledge_node_id", unique: true
    t.index ["user_id", "mastery_level"], name: "index_user_masteries_on_user_id_and_mastery_level"
    t.index ["user_id", "status"], name: "index_user_masteries_on_user_id_and_status"
    t.index ["user_id"], name: "index_user_masteries_on_user_id"
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
    t.boolean "is_paid", default: false
    t.datetime "valid_until"
    t.string "subscription_type"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_paid"], name: "index_users_on_is_paid"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["valid_until"], name: "index_users_on_valid_until"
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
  add_foreign_key "analysis_results", "questions"
  add_foreign_key "analysis_results", "study_sets"
  add_foreign_key "analysis_results", "users"
  add_foreign_key "chunk_questions", "document_chunks"
  add_foreign_key "chunk_questions", "questions"
  add_foreign_key "document_chunks", "study_materials"
  add_foreign_key "embeddings", "document_chunks"
  add_foreign_key "exam_answers", "exam_sessions"
  add_foreign_key "exam_answers", "questions"
  add_foreign_key "exam_notifications", "exam_schedules"
  add_foreign_key "exam_notifications", "users"
  add_foreign_key "exam_schedules", "certifications"
  add_foreign_key "exam_sessions", "study_sets"
  add_foreign_key "exam_sessions", "users"
  add_foreign_key "knowledge_edges", "knowledge_nodes"
  add_foreign_key "knowledge_edges", "knowledge_nodes", column: "related_node_id"
  add_foreign_key "knowledge_nodes", "study_materials"
  add_foreign_key "learning_recommendations", "analysis_results"
  add_foreign_key "learning_recommendations", "study_sets"
  add_foreign_key "learning_recommendations", "users"
  add_foreign_key "options", "questions"
  add_foreign_key "payments", "users"
  add_foreign_key "questions", "study_materials"
  add_foreign_key "solid_queue_batch_jobs", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_jobs", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_processes", column: "process_id", on_delete: :nullify
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_ready_executions", column: "ready_execution_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_paused_jobs", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_processes", column: "process_id", on_delete: :nullify
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "study_materials", "study_sets"
  add_foreign_key "study_sets", "users"
  add_foreign_key "subscriptions", "payments"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "test_answers", "test_questions"
  add_foreign_key "test_questions", "questions"
  add_foreign_key "test_questions", "test_sessions"
  add_foreign_key "test_sessions", "study_sets"
  add_foreign_key "test_sessions", "users"
  add_foreign_key "user_masteries", "knowledge_nodes"
  add_foreign_key "user_masteries", "users"
  add_foreign_key "wrong_answers", "questions"
  add_foreign_key "wrong_answers", "study_sets"
  add_foreign_key "wrong_answers", "users"
end
