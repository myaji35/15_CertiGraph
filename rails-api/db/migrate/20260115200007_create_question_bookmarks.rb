class CreateQuestionBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :question_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :test_question, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :test_session, null: false, foreign_key: true
      t.text :reason
      t.datetime :bookmarked_at
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :question_bookmarks, [:user_id, :test_question_id], unique: true
    add_index :question_bookmarks, [:user_id, :question_id]
    add_index :question_bookmarks, [:test_session_id, :is_active]
    add_index :question_bookmarks, :bookmarked_at
  end
end
