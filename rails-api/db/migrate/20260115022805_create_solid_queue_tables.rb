class CreateSolidQueueTables < ActiveRecord::Migration[7.2]
  def change
    create_table :solid_queue_jobs, id: :integer, force: true do |t|
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.string :class_name, null: false
      t.text :arguments, null: false
      t.integer :executions, default: 0, null: false
      t.string :exception_executions, default: "0", null: false
      t.datetime :finished_at
      t.string :scheduled_at
      t.string :locked_at
      t.string :locked_by
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :queue_name, :finished_at ], name: :index_solid_queue_jobs_on_queue_name_and_finished_at
      t.index [ :scheduled_at ], name: :index_solid_queue_jobs_on_scheduled_at
    end

    create_table :solid_queue_paused_jobs, id: :integer, force: true do |t|
      t.integer :job_id, null: false
      t.string :queue_name, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :queue_name ], name: :index_solid_queue_paused_jobs_on_queue_name
    end

    create_table :solid_queue_scheduled_executions, id: :integer, force: true do |t|
      t.integer :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :queue_name, :scheduled_at ], name: :idx_solid_queue_sched_exec_queue_sched_at
    end

    create_table :solid_queue_processes, id: :integer, force: true do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :kind, :last_heartbeat_at ], name: :index_solid_queue_processes_on_kind_and_last_heartbeat_at
    end

    create_table :solid_queue_ready_executions, id: :integer, force: true do |t|
      t.integer :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.integer :process_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :queue_name, :priority ], name: :idx_solid_queue_ready_exec_queue_priority
      t.index [ :process_id ], name: :index_solid_queue_ready_executions_on_process_id
    end

    create_table :solid_queue_claimed_executions, id: :integer, force: true do |t|
      t.integer :ready_execution_id, null: false
      t.integer :process_id, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :ready_execution_id ], name: :idx_solid_queue_claimed_exec_ready_exec_id, unique: true
      t.index [ :process_id, :created_at ], name: :idx_solid_queue_claimed_exec_proc_created
    end

    create_table :solid_queue_failed_executions, id: :integer, force: true do |t|
      t.integer :job_id, null: false
      t.string :queue_name, null: false
      t.text :exception
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :queue_name, :created_at ], name: :idx_solid_queue_failed_exec_queue_created
    end

    create_table :solid_queue_batches, id: :integer, force: true do |t|
      t.string :status, default: "enqueued", null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :status ], name: :index_solid_queue_batches_on_status
    end

    create_table :solid_queue_batch_jobs, id: :integer, force: true do |t|
      t.integer :batch_id, null: false
      t.integer :job_id, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :batch_id ], name: :index_solid_queue_batch_jobs_on_batch_id
      t.index [ :job_id ], name: :index_solid_queue_batch_jobs_on_job_id, unique: true
    end

    # Foreign keys
    add_foreign_key :solid_queue_paused_jobs, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_processes, column: :process_id, on_delete: :nullify
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_ready_executions, column: :ready_execution_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_processes, column: :process_id, on_delete: :nullify
    add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_batch_jobs, :solid_queue_batches, column: :batch_id, on_delete: :cascade
    add_foreign_key :solid_queue_batch_jobs, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end
end
