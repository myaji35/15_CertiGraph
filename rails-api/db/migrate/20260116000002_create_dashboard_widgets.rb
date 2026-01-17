class CreateDashboardWidgets < ActiveRecord::Migration[7.2]
  def change
    create_table :dashboard_widgets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :widget_type, null: false
      t.string :title, null: false
      t.json :configuration, default: {}
      t.integer :position, default: 0
      t.boolean :visible, default: true
      t.string :layout, default: 'medium'
      t.integer :width, default: 6
      t.integer :height, default: 4
      t.string :refresh_interval, default: '5s'

      t.timestamps
    end

    add_index :dashboard_widgets, [:user_id, :position]
    add_index :dashboard_widgets, [:user_id, :widget_type]
    add_index :dashboard_widgets, :visible
  end
end
