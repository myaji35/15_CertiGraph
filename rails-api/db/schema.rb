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

ActiveRecord::Schema[7.2].define(version: 2026_01_16_190510) do
  create_table "ab_test_assignments", force: :cascade do |t|
    t.integer "ab_test_id", null: false
    t.integer "user_id", null: false
    t.string "variant", null: false
    t.datetime "assigned_at", null: false
    t.datetime "first_interaction_at"
    t.datetime "last_interaction_at"
    t.integer "interaction_count", default: 0
    t.boolean "converted", default: false
    t.datetime "converted_at"
    t.json "conversion_data", default: {}
    t.json "metrics", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ab_test_id", "user_id"], name: "index_ab_test_assignments_on_ab_test_id_and_user_id", unique: true
    t.index ["ab_test_id"], name: "index_ab_test_assignments_on_ab_test_id"
    t.index ["converted"], name: "index_ab_test_assignments_on_converted"
    t.index ["user_id"], name: "index_ab_test_assignments_on_user_id"
    t.index ["variant"], name: "index_ab_test_assignments_on_variant"
  end

  create_table "ab_tests", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "test_type", null: false
    t.string "status", default: "draft"
    t.json "variants", default: {}
    t.float "traffic_allocation", default: 1.0
    t.integer "sample_size_target"
    t.json "targeting_criteria", default: {}
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "min_duration_days", default: 7
    t.integer "max_duration_days", default: 30
    t.json "primary_metrics", default: []
    t.json "secondary_metrics", default: []
    t.json "results", default: {}
    t.float "confidence_level", default: 0.0
    t.float "p_value"
    t.string "winner_variant"
    t.boolean "is_significant", default: false
    t.integer "created_by_id"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_ab_tests_on_created_by_id"
    t.index ["name"], name: "index_ab_tests_on_name"
    t.index ["status", "started_at"], name: "index_ab_tests_on_status_and_started_at"
    t.index ["status"], name: "index_ab_tests_on_status"
    t.index ["test_type"], name: "index_ab_tests_on_test_type"
  end

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

  create_table "concept_synonyms", force: :cascade do |t|
    t.integer "knowledge_node_id", null: false
    t.string "synonym_name", null: false
    t.string "synonym_type", default: "synonym", null: false
    t.float "similarity_score", default: 1.0
    t.string "source", default: "manual"
    t.json "metadata", default: {}
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_concept_synonyms_on_active"
    t.index ["knowledge_node_id"], name: "index_concept_synonyms_on_knowledge_node_id"
    t.index ["synonym_name", "knowledge_node_id"], name: "index_concept_synonyms_on_synonym_name_and_knowledge_node_id", unique: true
    t.index ["synonym_name"], name: "index_concept_synonyms_on_synonym_name"
    t.index ["synonym_type"], name: "index_concept_synonyms_on_synonym_type"
  end

  create_table "dashboard_widgets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "widget_type", null: false
    t.string "title", null: false
    t.json "configuration", default: {}
    t.integer "position", default: 0
    t.boolean "visible", default: true
    t.string "layout", default: "medium"
    t.integer "width", default: 6
    t.integer "height", default: 4
    t.string "refresh_interval", default: "5s"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "position"], name: "index_dashboard_widgets_on_user_id_and_position"
    t.index ["user_id", "widget_type"], name: "index_dashboard_widgets_on_user_id_and_widget_type"
    t.index ["user_id"], name: "index_dashboard_widgets_on_user_id"
    t.index ["visible"], name: "index_dashboard_widgets_on_visible"
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
    t.string "randomization_seed"
    t.string "randomization_strategy", default: "full_random"
    t.boolean "randomization_enabled", default: true
    t.text "metadata"
    t.index ["randomization_seed"], name: "index_exam_sessions_on_randomization_seed"
    t.index ["randomization_strategy"], name: "index_exam_sessions_on_randomization_strategy"
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
    t.string "strength", default: "medium"
    t.integer "depth", default: 1
    t.float "confidence_score", default: 0.0
    t.boolean "auto_generated", default: false
    t.boolean "verified_by_user", default: false
    t.text "llm_reasoning"
    t.index ["active"], name: "index_knowledge_edges_on_active"
    t.index ["auto_generated"], name: "index_knowledge_edges_on_auto_generated"
    t.index ["confidence_score"], name: "index_knowledge_edges_on_confidence_score"
    t.index ["depth"], name: "index_knowledge_edges_on_depth"
    t.index ["knowledge_node_id", "related_node_id"], name: "index_knowledge_edges_on_knowledge_node_id_and_related_node_id", unique: true
    t.index ["knowledge_node_id"], name: "index_knowledge_edges_on_knowledge_node_id"
    t.index ["related_node_id"], name: "index_knowledge_edges_on_related_node_id"
    t.index ["relationship_type", "weight"], name: "index_knowledge_edges_on_relationship_type_and_weight"
    t.index ["relationship_type"], name: "index_knowledge_edges_on_relationship_type"
    t.index ["strength"], name: "index_knowledge_edges_on_strength"
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
    t.text "definition"
    t.json "examples", default: []
    t.integer "frequency", default: 0
    t.float "mastery_threshold", default: 0.8
    t.integer "estimated_learning_minutes", default: 30
    t.json "tags", default: []
    t.string "concept_category"
    t.float "extraction_confidence", default: 0.0
    t.string "normalized_name"
    t.boolean "is_primary", default: true
    t.index ["active"], name: "index_knowledge_nodes_on_active"
    t.index ["concept_category"], name: "index_knowledge_nodes_on_concept_category"
    t.index ["frequency"], name: "index_knowledge_nodes_on_frequency"
    t.index ["is_primary"], name: "index_knowledge_nodes_on_is_primary"
    t.index ["name"], name: "index_knowledge_nodes_on_name"
    t.index ["normalized_name"], name: "index_knowledge_nodes_on_normalized_name"
    t.index ["parent_name"], name: "index_knowledge_nodes_on_parent_name"
    t.index ["study_material_id", "level"], name: "index_knowledge_nodes_on_study_material_id_and_level"
    t.index ["study_material_id", "normalized_name"], name: "index_knowledge_nodes_on_study_material_id_and_normalized_name"
    t.index ["study_material_id", "parent_name"], name: "index_knowledge_nodes_on_study_material_id_and_parent_name"
    t.index ["study_material_id"], name: "index_knowledge_nodes_on_study_material_id"
  end

  create_table "learning_paths", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_material_id", null: false
    t.integer "target_node_id"
    t.string "path_name", null: false
    t.string "path_type", default: "shortest"
    t.string "status", default: "active"
    t.json "node_sequence", default: []
    t.json "edge_sequence", default: []
    t.integer "total_nodes", default: 0
    t.integer "completed_nodes", default: 0
    t.float "completion_percentage", default: 0.0
    t.integer "difficulty_level", default: 3
    t.integer "estimated_hours", default: 0
    t.integer "actual_hours", default: 0
    t.float "path_score", default: 0.0
    t.float "mastery_requirement", default: 0.8
    t.integer "priority", default: 5
    t.datetime "started_at"
    t.datetime "last_activity_at"
    t.datetime "completed_at"
    t.datetime "estimated_completion_at"
    t.json "mastery_checkpoints", default: {}
    t.json "learning_statistics", default: {}
    t.json "alternative_paths", default: []
    t.text "description"
    t.text "success_criteria"
    t.json "metadata", default: {}
    t.integer "views_count", default: 0
    t.integer "abandonment_count", default: 0
    t.float "user_satisfaction", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completion_percentage"], name: "index_learning_paths_on_completion_percentage"
    t.index ["estimated_completion_at"], name: "index_learning_paths_on_estimated_completion_at"
    t.index ["path_score"], name: "index_learning_paths_on_path_score"
    t.index ["path_type"], name: "index_learning_paths_on_path_type"
    t.index ["started_at"], name: "index_learning_paths_on_started_at"
    t.index ["status", "priority"], name: "idx_learning_paths_status_priority"
    t.index ["study_material_id"], name: "index_learning_paths_on_study_material_id"
    t.index ["target_node_id"], name: "index_learning_paths_on_target_node_id"
    t.index ["user_id", "status"], name: "idx_learning_paths_user_status"
    t.index ["user_id", "study_material_id"], name: "idx_learning_paths_user_material"
    t.index ["user_id"], name: "index_learning_paths_on_user_id"
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
    t.string "recommendation_algorithm"
    t.string "algorithm_version"
    t.float "confidence_level", default: 0.0
    t.float "diversity_score", default: 0.0
    t.float "novelty_score", default: 0.0
    t.text "explanation_text"
    t.integer "similar_users_count", default: 0
    t.float "cf_score"
    t.float "cb_score"
    t.float "hybrid_weight_cf", default: 0.8
    t.float "hybrid_weight_cb", default: 0.2
    t.integer "impressions_count", default: 0
    t.integer "clicks_count", default: 0
    t.index ["analysis_result_id"], name: "index_learning_recommendations_on_analysis_result_id"
    t.index ["confidence_level"], name: "index_learning_recommendations_on_confidence_level"
    t.index ["created_at"], name: "index_learning_recommendations_on_created_at"
    t.index ["impressions_count", "clicks_count"], name: "idx_on_impressions_count_clicks_count_eabcb61dab"
    t.index ["learning_efficiency_index"], name: "index_learning_recommendations_on_learning_efficiency_index"
    t.index ["priority_level"], name: "index_learning_recommendations_on_priority_level"
    t.index ["recommendation_algorithm"], name: "index_learning_recommendations_on_recommendation_algorithm"
    t.index ["recommendation_type", "status"], name: "idx_recommendations_type_status"
    t.index ["study_set_id"], name: "index_learning_recommendations_on_study_set_id"
    t.index ["user_id", "study_set_id", "status"], name: "idx_recommendations_user_study_status"
    t.index ["user_id"], name: "index_learning_recommendations_on_user_id"
  end

  create_table "ml_models", force: :cascade do |t|
    t.string "name", null: false
    t.string "model_type", null: false
    t.text "description"
    t.string "algorithm"
    t.string "version", null: false
    t.string "status", default: "untrained"
    t.integer "training_samples_count", default: 0
    t.integer "validation_samples_count", default: 0
    t.integer "test_samples_count", default: 0
    t.json "model_parameters", default: {}
    t.json "model_weights", default: {}
    t.json "feature_importance", default: {}
    t.json "training_history", default: []
    t.float "accuracy", default: 0.0
    t.float "precision", default: 0.0
    t.float "recall", default: 0.0
    t.float "f1_score", default: 0.0
    t.float "mae"
    t.float "rmse"
    t.json "confusion_matrix", default: {}
    t.json "features", default: []
    t.json "target_variable"
    t.json "preprocessing_config", default: {}
    t.datetime "trained_at"
    t.datetime "deployed_at"
    t.datetime "last_used_at"
    t.integer "prediction_count", default: 0
    t.integer "parent_model_id"
    t.boolean "is_active", default: false
    t.integer "trained_by_id"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accuracy"], name: "index_ml_models_on_accuracy"
    t.index ["model_type", "is_active"], name: "index_ml_models_on_model_type_and_is_active"
    t.index ["model_type"], name: "index_ml_models_on_model_type"
    t.index ["name"], name: "index_ml_models_on_name"
    t.index ["parent_model_id"], name: "index_ml_models_on_parent_model_id"
    t.index ["status"], name: "index_ml_models_on_status"
    t.index ["trained_by_id"], name: "index_ml_models_on_trained_by_id"
    t.index ["version"], name: "index_ml_models_on_version"
  end

  create_table "ml_predictions", force: :cascade do |t|
    t.integer "ml_model_id", null: false
    t.integer "user_id", null: false
    t.string "prediction_type", null: false
    t.json "input_features", default: {}
    t.json "prediction_result", default: {}
    t.float "confidence_score", default: 0.0
    t.json "probability_distribution", default: {}
    t.integer "study_material_id"
    t.integer "question_id"
    t.string "context_type"
    t.bigint "context_id"
    t.string "actual_outcome"
    t.boolean "was_correct"
    t.float "prediction_error"
    t.integer "inference_time_ms"
    t.datetime "predicted_at", null: false
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ml_model_id", "was_correct"], name: "index_ml_predictions_on_ml_model_id_and_was_correct"
    t.index ["ml_model_id"], name: "index_ml_predictions_on_ml_model_id"
    t.index ["predicted_at"], name: "index_ml_predictions_on_predicted_at"
    t.index ["prediction_type"], name: "index_ml_predictions_on_prediction_type"
    t.index ["question_id"], name: "index_ml_predictions_on_question_id"
    t.index ["study_material_id"], name: "index_ml_predictions_on_study_material_id"
    t.index ["user_id", "prediction_type"], name: "index_ml_predictions_on_user_id_and_prediction_type"
    t.index ["user_id"], name: "index_ml_predictions_on_user_id"
  end

  create_table "options", force: :cascade do |t|
    t.integer "question_id", null: false
    t.text "content"
    t.boolean "is_correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "passages", force: :cascade do |t|
    t.integer "study_material_id", null: false
    t.text "content", null: false
    t.string "passage_type", default: "text"
    t.integer "position"
    t.json "metadata", default: {}
    t.boolean "has_image", default: false
    t.boolean "has_table", default: false
    t.integer "character_count", default: 0
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["passage_type"], name: "index_passages_on_passage_type"
    t.index ["study_material_id", "position"], name: "index_passages_on_study_material_id_and_position"
    t.index ["study_material_id"], name: "index_passages_on_study_material_id"
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

  create_table "performance_snapshots", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_set_id"
    t.date "snapshot_date", null: false
    t.string "period_type", default: "daily"
    t.float "overall_mastery_level", default: 0.0
    t.float "overall_accuracy", default: 0.0
    t.integer "total_attempts", default: 0
    t.integer "total_correct", default: 0
    t.float "completion_percentage", default: 0.0
    t.integer "mastered_nodes_count", default: 0
    t.integer "learning_nodes_count", default: 0
    t.integer "weak_nodes_count", default: 0
    t.integer "untested_nodes_count", default: 0
    t.integer "total_study_minutes", default: 0
    t.integer "avg_session_minutes", default: 0
    t.integer "study_sessions_count", default: 0
    t.float "mastery_change", default: 0.0
    t.float "accuracy_change", default: 0.0
    t.integer "attempts_change", default: 0
    t.json "subject_breakdown", default: {}
    t.json "chapter_breakdown", default: {}
    t.json "concept_breakdown", default: {}
    t.integer "morning_study_minutes", default: 0
    t.integer "afternoon_study_minutes", default: 0
    t.integer "evening_study_minutes", default: 0
    t.integer "night_study_minutes", default: 0
    t.float "morning_accuracy", default: 0.0
    t.float "afternoon_accuracy", default: 0.0
    t.float "evening_accuracy", default: 0.0
    t.float "night_accuracy", default: 0.0
    t.float "predicted_exam_score", default: 0.0
    t.integer "estimated_days_to_mastery", default: 0
    t.float "goal_achievement_probability", default: 0.0
    t.float "percentile_rank", default: 0.0
    t.float "avg_mastery_vs_others", default: 0.0
    t.json "top_strengths", default: []
    t.json "top_weaknesses", default: []
    t.json "recent_improvements", default: []
    t.json "study_streak_data", default: {}
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completion_percentage"], name: "index_performance_snapshots_on_completion_percentage"
    t.index ["overall_mastery_level"], name: "index_performance_snapshots_on_overall_mastery_level"
    t.index ["snapshot_date", "period_type"], name: "index_performance_snapshots_on_snapshot_date_and_period_type"
    t.index ["study_set_id"], name: "index_performance_snapshots_on_study_set_id"
    t.index ["user_id", "snapshot_date"], name: "index_performance_snapshots_on_user_id_and_snapshot_date"
    t.index ["user_id", "study_set_id", "snapshot_date"], name: "idx_on_user_id_study_set_id_snapshot_date_4474d52b40"
    t.index ["user_id"], name: "index_performance_snapshots_on_user_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_material_id", null: false
    t.integer "payment_id"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.integer "download_count", default: 0
    t.integer "download_limit", default: 5
    t.datetime "purchased_at"
    t.datetime "expires_at"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_purchases_on_expires_at"
    t.index ["payment_id"], name: "index_purchases_on_payment_id"
    t.index ["purchased_at"], name: "index_purchases_on_purchased_at"
    t.index ["status"], name: "index_purchases_on_status"
    t.index ["study_material_id"], name: "index_purchases_on_study_material_id"
    t.index ["user_id", "study_material_id"], name: "index_purchases_on_user_id_and_study_material_id", unique: true
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "question_bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "test_question_id", null: false
    t.integer "question_id", null: false
    t.integer "test_session_id", null: false
    t.text "reason"
    t.datetime "bookmarked_at"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookmarked_at"], name: "index_question_bookmarks_on_bookmarked_at"
    t.index ["question_id"], name: "index_question_bookmarks_on_question_id"
    t.index ["test_question_id"], name: "index_question_bookmarks_on_test_question_id"
    t.index ["test_session_id", "is_active"], name: "index_question_bookmarks_on_test_session_id_and_is_active"
    t.index ["test_session_id"], name: "index_question_bookmarks_on_test_session_id"
    t.index ["user_id", "question_id"], name: "index_question_bookmarks_on_user_id_and_question_id"
    t.index ["user_id", "test_question_id"], name: "index_question_bookmarks_on_user_id_and_test_question_id", unique: true
    t.index ["user_id"], name: "index_question_bookmarks_on_user_id"
  end

  create_table "question_concepts", force: :cascade do |t|
    t.integer "question_id", null: false
    t.integer "knowledge_node_id", null: false
    t.integer "importance_level", default: 5, null: false
    t.float "relevance_score", default: 0.5
    t.boolean "is_primary_concept", default: false
    t.string "extraction_method", default: "ai"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["importance_level"], name: "index_question_concepts_on_importance_level"
    t.index ["is_primary_concept"], name: "index_question_concepts_on_is_primary_concept"
    t.index ["knowledge_node_id"], name: "index_question_concepts_on_knowledge_node_id"
    t.index ["question_id", "knowledge_node_id"], name: "idx_question_concepts_unique", unique: true
    t.index ["question_id"], name: "index_question_concepts_on_question_id"
    t.index ["relevance_score"], name: "index_question_concepts_on_relevance_score"
  end

  create_table "question_passages", force: :cascade do |t|
    t.integer "question_id", null: false
    t.integer "passage_id", null: false
    t.boolean "is_primary", default: false
    t.integer "relevance_score", default: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["passage_id", "is_primary"], name: "index_question_passages_on_passage_id_and_is_primary"
    t.index ["passage_id"], name: "index_question_passages_on_passage_id"
    t.index ["question_id", "passage_id"], name: "index_question_passages_on_question_id_and_passage_id", unique: true
    t.index ["question_id"], name: "index_question_passages_on_question_id"
  end

# Could not dump table "questions" because of following StandardError
#   Unknown type 'vector' for column 'embedding'


  create_table "randomization_stats", force: :cascade do |t|
    t.integer "study_material_id", null: false
    t.integer "question_id", null: false
    t.integer "option_id", null: false
    t.string "option_label", null: false
    t.integer "position_0_count", default: 0
    t.integer "position_1_count", default: 0
    t.integer "position_2_count", default: 0
    t.integer "position_3_count", default: 0
    t.integer "position_4_count", default: 0
    t.integer "total_randomizations", default: 0
    t.float "chi_square_statistic", default: 0.0
    t.float "p_value", default: 1.0
    t.float "bias_score", default: 0.0
    t.boolean "is_uniform", default: true
    t.json "position_distribution"
    t.json "analysis_metadata"
    t.datetime "last_analyzed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bias_score"], name: "index_randomization_stats_on_bias_score"
    t.index ["chi_square_statistic"], name: "index_randomization_stats_on_chi_square_statistic"
    t.index ["is_uniform"], name: "index_randomization_stats_on_is_uniform"
    t.index ["option_id"], name: "index_randomization_stats_on_option_id"
    t.index ["question_id"], name: "index_randomization_stats_on_question_id"
    t.index ["study_material_id", "question_id"], name: "idx_rand_stats_material_question"
    t.index ["study_material_id"], name: "index_randomization_stats_on_study_material_id"
  end

  create_table "recommendation_ab_tests", force: :cascade do |t|
    t.string "test_name", null: false
    t.string "variant_name", null: false
    t.integer "user_id", null: false
    t.integer "learning_recommendation_id"
    t.string "status", default: "active"
    t.json "variant_config"
    t.json "result_metrics"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_recommendation_id"], name: "index_recommendation_ab_tests_on_learning_recommendation_id"
    t.index ["test_name", "variant_name"], name: "index_recommendation_ab_tests_on_test_name_and_variant_name"
    t.index ["user_id", "status"], name: "index_recommendation_ab_tests_on_user_id_and_status"
    t.index ["user_id"], name: "index_recommendation_ab_tests_on_user_id"
  end

  create_table "recommendation_feedbacks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "learning_recommendation_id", null: false
    t.string "feedback_type", null: false
    t.integer "rating"
    t.text "comment"
    t.float "time_spent_seconds"
    t.boolean "was_helpful"
    t.json "interaction_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_recommendation_feedbacks_on_created_at"
    t.index ["learning_recommendation_id"], name: "index_recommendation_feedbacks_on_learning_recommendation_id"
    t.index ["user_id", "feedback_type"], name: "index_recommendation_feedbacks_on_user_id_and_feedback_type"
    t.index ["user_id"], name: "index_recommendation_feedbacks_on_user_id"
  end

  create_table "recommendation_metrics", force: :cascade do |t|
    t.integer "learning_recommendation_id", null: false
    t.date "metric_date", null: false
    t.integer "impressions", default: 0
    t.integer "clicks", default: 0
    t.integer "completions", default: 0
    t.integer "dismissals", default: 0
    t.float "ctr"
    t.float "completion_rate"
    t.float "avg_rating"
    t.float "avg_time_spent"
    t.json "performance_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_recommendation_id"], name: "index_recommendation_metrics_on_learning_recommendation_id"
    t.index ["metric_date", "learning_recommendation_id"], name: "idx_metrics_date_recommendation"
  end

  create_table "review_votes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "review_id", null: false
    t.boolean "helpful", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["helpful"], name: "index_review_votes_on_helpful"
    t.index ["review_id"], name: "index_review_votes_on_review_id"
    t.index ["user_id", "review_id"], name: "index_review_votes_on_user_id_and_review_id", unique: true
    t.index ["user_id"], name: "index_review_votes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_material_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.integer "helpful_count", default: 0
    t.integer "not_helpful_count", default: 0
    t.boolean "verified_purchase", default: false
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["helpful_count"], name: "index_reviews_on_helpful_count"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["study_material_id"], name: "index_reviews_on_study_material_id"
    t.index ["user_id", "study_material_id"], name: "index_reviews_on_user_id_and_study_material_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.index ["verified_purchase"], name: "index_reviews_on_verified_purchase"
  end

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
    t.boolean "graph_built", default: false
    t.datetime "graph_built_at"
    t.json "graph_metadata"
    t.text "graph_error"
    t.string "category"
    t.integer "difficulty", default: 3
    t.json "content_metadata", default: {}
    t.boolean "is_public", default: false, null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.integer "sales_count", default: 0
    t.decimal "avg_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "total_reviews", default: 0
    t.string "difficulty_level"
    t.json "tags", default: []
    t.datetime "published_at"
    t.bigint "file_size"
    t.string "file_checksum"
    t.string "mime_type"
    t.string "upload_status", default: "pending"
    t.integer "upload_progress", default: 0
    t.datetime "upload_started_at"
    t.datetime "upload_completed_at"
    t.text "upload_error"
    t.integer "chunk_count"
    t.integer "chunks_uploaded", default: 0
    t.string "multipart_upload_id"
    t.integer "retry_count", default: 0
    t.datetime "last_accessed_at"
    t.bigint "storage_usage_bytes", default: 0
    t.boolean "is_backed_up", default: false
    t.datetime "backup_completed_at"
    t.index ["avg_rating"], name: "index_study_materials_on_avg_rating"
    t.index ["category"], name: "index_study_materials_on_category"
    t.index ["difficulty"], name: "index_study_materials_on_difficulty"
    t.index ["difficulty_level"], name: "index_study_materials_on_difficulty_level"
    t.index ["file_checksum"], name: "index_study_materials_on_file_checksum"
    t.index ["is_public"], name: "index_study_materials_on_is_public"
    t.index ["last_accessed_at"], name: "index_study_materials_on_last_accessed_at"
    t.index ["price"], name: "index_study_materials_on_price"
    t.index ["published_at"], name: "index_study_materials_on_published_at"
    t.index ["study_set_id"], name: "index_study_materials_on_study_set_id"
    t.index ["upload_status"], name: "index_study_materials_on_upload_status"
  end

  create_table "study_sets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "description"
    t.date "exam_date"
    t.string "certification"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "study_materials_count", default: 0, null: false
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

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.string "taggable_type", null: false
    t.integer "taggable_id", null: false
    t.string "context"
    t.integer "relevance_score", default: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id", "tag_id"], name: "idx_taggings_unique", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.integer "usage_count", default: 0
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_tags_on_category"
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["usage_count"], name: "index_tags_on_usage_count"
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
    t.datetime "time_started_at"
    t.integer "time_spent", default: 0
    t.integer "answer_change_count", default: 0
    t.index ["question_id"], name: "index_test_questions_on_question_id"
    t.index ["test_session_id", "question_number"], name: "index_test_questions_on_test_session_id_and_question_number"
    t.index ["test_session_id"], name: "index_test_questions_on_test_session_id"
    t.index ["time_started_at"], name: "index_test_questions_on_time_started_at"
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
    t.datetime "paused_at"
    t.datetime "resumed_at"
    t.integer "total_pause_duration", default: 0
    t.integer "pause_count", default: 0
    t.boolean "is_paused", default: false
    t.datetime "last_autosave_at"
    t.integer "autosave_count", default: 0
    t.integer "current_question_id"
    t.integer "answer_change_count", default: 0
    t.integer "bookmark_count", default: 0
    t.decimal "average_time_per_question", precision: 10, scale: 2
    t.datetime "estimated_completion_time"
    t.index ["current_question_id"], name: "index_test_sessions_on_current_question_id"
    t.index ["is_paused"], name: "index_test_sessions_on_is_paused"
    t.index ["last_autosave_at"], name: "index_test_sessions_on_last_autosave_at"
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
    t.integer "consecutive_correct", default: 0
    t.integer "consecutive_incorrect", default: 0
    t.integer "fastest_solve_seconds"
    t.integer "avg_solve_seconds"
    t.integer "study_streak_days", default: 0
    t.date "last_review_date"
    t.date "next_review_date"
    t.float "retention_score", default: 0.0
    t.integer "difficulty_rating", default: 3
    t.string "time_of_day_best_performance"
    t.index ["color"], name: "index_user_masteries_on_color"
    t.index ["consecutive_correct"], name: "index_user_masteries_on_consecutive_correct"
    t.index ["knowledge_node_id"], name: "index_user_masteries_on_knowledge_node_id"
    t.index ["next_review_date"], name: "index_user_masteries_on_next_review_date"
    t.index ["retention_score"], name: "index_user_masteries_on_retention_score"
    t.index ["status"], name: "index_user_masteries_on_status"
    t.index ["user_id", "knowledge_node_id"], name: "index_user_masteries_on_user_id_and_knowledge_node_id", unique: true
    t.index ["user_id", "mastery_level"], name: "index_user_masteries_on_user_id_and_mastery_level"
    t.index ["user_id", "status"], name: "index_user_masteries_on_user_id_and_status"
    t.index ["user_id"], name: "index_user_masteries_on_user_id"
  end

  create_table "user_similarity_scores", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "similar_user_id", null: false
    t.float "similarity_score", null: false
    t.string "similarity_type"
    t.integer "common_concepts_count"
    t.json "similarity_breakdown"
    t.datetime "calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["similarity_score"], name: "index_user_similarity_scores_on_similarity_score", order: :desc
    t.index ["user_id", "similar_user_id"], name: "index_user_similarity_scores_on_user_id_and_similar_user_id", unique: true
    t.index ["user_id"], name: "index_user_similarity_scores_on_user_id"
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
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "last_activity_at"
    t.boolean "security_alerts_enabled", default: true
    t.boolean "suspicious_login_detected", default: false
    t.text "bio"
    t.string "phone_number"
    t.date "date_of_birth"
    t.string "avatar_url"
    t.json "preferences", default: {}
    t.json "notification_settings", default: {}
    t.json "login_history", default: []
    t.string "account_status", default: "active"
    t.datetime "deactivated_at"
    t.datetime "deletion_requested_at"
    t.json "social_links", default: {}
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.text "otp_backup_codes"
    t.boolean "otp_required_for_login", default: false
    t.boolean "terms_agreed"
    t.boolean "privacy_agreed"
    t.boolean "marketing_agreed"
    t.integer "study_sets_count", default: 0, null: false
    t.integer "exam_sessions_count", default: 0, null: false
    t.integer "test_sessions_count", default: 0, null: false
    t.index ["account_status"], name: "index_users_on_account_status"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_otp_secret"], name: "index_users_on_encrypted_otp_secret", unique: true
    t.index ["failed_attempts"], name: "index_users_on_failed_attempts"
    t.index ["is_paid"], name: "index_users_on_is_paid"
    t.index ["last_activity_at"], name: "index_users_on_last_activity_at"
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["valid_until"], name: "index_users_on_valid_until"
  end

  create_table "weakness_reports", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_material_id"
    t.string "report_type", default: "comprehensive"
    t.date "period_start"
    t.date "period_end"
    t.string "status", default: "generated"
    t.json "weakness_by_concept", default: {}
    t.json "weakness_by_difficulty", default: {}
    t.json "weakness_by_question_type", default: {}
    t.json "weakness_by_topic", default: {}
    t.integer "overall_weakness_score", default: 0
    t.json "critical_weaknesses", default: []
    t.json "moderate_weaknesses", default: []
    t.json "minor_weaknesses", default: []
    t.json "improvement_over_time", default: {}
    t.integer "improvement_percentage"
    t.json "improvement_by_concept", default: {}
    t.json "peer_comparison", default: {}
    t.integer "percentile_rank"
    t.json "priority_recommendations", default: []
    t.json "learning_path_suggestions", default: []
    t.integer "estimated_study_hours"
    t.json "heatmap_data", default: {}
    t.json "trend_chart_data", default: {}
    t.json "comparison_chart_data", default: {}
    t.string "pdf_status", default: "pending"
    t.string "pdf_url"
    t.datetime "pdf_generated_at"
    t.json "statistics", default: {}
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["overall_weakness_score"], name: "index_weakness_reports_on_overall_weakness_score"
    t.index ["period_start"], name: "index_weakness_reports_on_period_start"
    t.index ["status"], name: "index_weakness_reports_on_status"
    t.index ["study_material_id"], name: "index_weakness_reports_on_study_material_id"
    t.index ["user_id", "report_type"], name: "index_weakness_reports_on_user_id_and_report_type"
    t.index ["user_id"], name: "index_weakness_reports_on_user_id"
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

  add_foreign_key "ab_test_assignments", "ab_tests"
  add_foreign_key "ab_test_assignments", "users"
  add_foreign_key "ab_tests", "users", column: "created_by_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analysis_results", "questions"
  add_foreign_key "analysis_results", "study_sets"
  add_foreign_key "analysis_results", "users"
  add_foreign_key "chunk_questions", "document_chunks"
  add_foreign_key "chunk_questions", "questions"
  add_foreign_key "concept_synonyms", "knowledge_nodes"
  add_foreign_key "dashboard_widgets", "users"
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
  add_foreign_key "learning_paths", "knowledge_nodes", column: "target_node_id"
  add_foreign_key "learning_paths", "study_materials"
  add_foreign_key "learning_paths", "users"
  add_foreign_key "learning_recommendations", "analysis_results"
  add_foreign_key "learning_recommendations", "study_sets"
  add_foreign_key "learning_recommendations", "users"
  add_foreign_key "ml_models", "ml_models", column: "parent_model_id"
  add_foreign_key "ml_models", "users", column: "trained_by_id"
  add_foreign_key "ml_predictions", "ml_models"
  add_foreign_key "ml_predictions", "users"
  add_foreign_key "options", "questions"
  add_foreign_key "passages", "study_materials"
  add_foreign_key "payments", "users"
  add_foreign_key "performance_snapshots", "study_sets"
  add_foreign_key "performance_snapshots", "users"
  add_foreign_key "purchases", "payments"
  add_foreign_key "purchases", "study_materials"
  add_foreign_key "purchases", "users"
  add_foreign_key "question_bookmarks", "questions"
  add_foreign_key "question_bookmarks", "test_questions"
  add_foreign_key "question_bookmarks", "test_sessions"
  add_foreign_key "question_bookmarks", "users"
  add_foreign_key "question_concepts", "knowledge_nodes"
  add_foreign_key "question_concepts", "questions"
  add_foreign_key "question_passages", "passages"
  add_foreign_key "question_passages", "questions"
  add_foreign_key "questions", "study_materials"
  add_foreign_key "randomization_stats", "questions"
  add_foreign_key "randomization_stats", "study_materials"
  add_foreign_key "recommendation_ab_tests", "learning_recommendations"
  add_foreign_key "recommendation_ab_tests", "users"
  add_foreign_key "recommendation_feedbacks", "learning_recommendations"
  add_foreign_key "recommendation_feedbacks", "users"
  add_foreign_key "recommendation_metrics", "learning_recommendations"
  add_foreign_key "review_votes", "reviews"
  add_foreign_key "review_votes", "users"
  add_foreign_key "reviews", "study_materials"
  add_foreign_key "reviews", "users"
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
  add_foreign_key "taggings", "tags"
  add_foreign_key "test_answers", "test_questions"
  add_foreign_key "test_questions", "questions"
  add_foreign_key "test_questions", "test_sessions"
  add_foreign_key "test_sessions", "study_sets"
  add_foreign_key "test_sessions", "users"
  add_foreign_key "user_masteries", "knowledge_nodes"
  add_foreign_key "user_masteries", "users"
  add_foreign_key "user_similarity_scores", "users"
  add_foreign_key "user_similarity_scores", "users", column: "similar_user_id"
  add_foreign_key "weakness_reports", "study_materials"
  add_foreign_key "weakness_reports", "users"
  add_foreign_key "wrong_answers", "questions"
  add_foreign_key "wrong_answers", "study_sets"
  add_foreign_key "wrong_answers", "users"
end
