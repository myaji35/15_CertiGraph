class UpdateExamSchedulesForCertificationHub < ActiveRecord::Migration[7.2]
  def change
    # exam_schedules 테이블이 이미 존재하므로 컬럼 추가/수정
    unless column_exists?(:exam_schedules, :certification_id)
      add_reference :exam_schedules, :certification, foreign_key: true
    end

    # 기존 컬럼이 없으면 추가
    unless column_exists?(:exam_schedules, :year)
      add_column :exam_schedules, :year, :integer
    end

    unless column_exists?(:exam_schedules, :round)
      add_column :exam_schedules, :round, :integer
    end

    unless column_exists?(:exam_schedules, :exam_type)
      add_column :exam_schedules, :exam_type, :string
    end

    unless column_exists?(:exam_schedules, :registration_start_date)
      add_column :exam_schedules, :registration_start_date, :date
    end

    unless column_exists?(:exam_schedules, :registration_end_date)
      add_column :exam_schedules, :registration_end_date, :date
    end

    unless column_exists?(:exam_schedules, :exam_date)
      add_column :exam_schedules, :exam_date, :date
    end

    unless column_exists?(:exam_schedules, :exam_time)
      add_column :exam_schedules, :exam_time, :time
    end

    unless column_exists?(:exam_schedules, :result_date)
      add_column :exam_schedules, :result_date, :date
    end

    unless column_exists?(:exam_schedules, :pass_rate)
      add_column :exam_schedules, :pass_rate, :float
    end

    unless column_exists?(:exam_schedules, :cutoff_score)
      add_column :exam_schedules, :cutoff_score, :float
    end

    unless column_exists?(:exam_schedules, :capacity)
      add_column :exam_schedules, :capacity, :integer
    end

    unless column_exists?(:exam_schedules, :applicants_count)
      add_column :exam_schedules, :applicants_count, :integer
    end

    unless column_exists?(:exam_schedules, :notice)
      add_column :exam_schedules, :notice, :text
    end

    unless column_exists?(:exam_schedules, :status)
      add_column :exam_schedules, :status, :string, default: 'scheduled'
    end

    unless column_exists?(:exam_schedules, :metadata)
      add_column :exam_schedules, :metadata, :json
    end

    # 인덱스 추가 (이미 없는 경우에만)
    unless index_exists?(:exam_schedules, [:certification_id, :year])
      add_index :exam_schedules, [:certification_id, :year]
    end

    unless index_exists?(:exam_schedules, [:year, :exam_date])
      add_index :exam_schedules, [:year, :exam_date]
    end

    unless index_exists?(:exam_schedules, :exam_date)
      add_index :exam_schedules, :exam_date
    end

    unless index_exists?(:exam_schedules, :status)
      add_index :exam_schedules, :status
    end

    unless index_exists?(:exam_schedules, :registration_start_date)
      add_index :exam_schedules, :registration_start_date
    end
  end
end