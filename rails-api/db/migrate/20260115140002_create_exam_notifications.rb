class CreateExamNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :exam_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exam_schedule, null: false, foreign_key: true
      t.string :notification_type, null: false # registration_open, exam_reminder, result_announcement
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.string :status, default: 'pending' # pending, sent, failed, cancelled
      t.string :channel # email, push, sms
      t.text :message
      t.json :metadata

      t.timestamps
    end

    add_index :exam_notifications, [:user_id, :status]
    add_index :exam_notifications, :scheduled_at
    add_index :exam_notifications, :notification_type
    add_index :exam_notifications, [:exam_schedule_id, :notification_type], name: 'index_exam_notif_on_schedule_and_type'
  end
end