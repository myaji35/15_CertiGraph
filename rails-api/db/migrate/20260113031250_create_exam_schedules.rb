class CreateExamSchedules < ActiveRecord::Migration[7.2]
  def change
    create_table :exam_schedules do |t|
      t.string :certification_code
      t.string :certification_name
      t.integer :exam_year
      t.integer :exam_round
      t.date :written_exam_date
      t.date :written_exam_reg_start
      t.date :written_exam_reg_end
      t.date :practical_exam_date
      t.date :practical_exam_reg_start
      t.date :practical_exam_reg_end
      t.date :announcement_date
      t.decimal :exam_fee
      t.string :exam_location
      t.json :additional_info

      t.timestamps
    end
  end
end
