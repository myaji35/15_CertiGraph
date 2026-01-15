class CreateCertifications < ActiveRecord::Migration[7.2]
  def change
    create_table :certifications do |t|
      t.string :name, null: false
      t.string :name_en
      t.string :organization, null: false # 한국산업인력공단, 대한상공회의소 등
      t.string :organization_en
      t.string :category # IT, 사회복지, 경영 등
      t.string :series # 기사, 산업기사, 기능사 등
      t.string :website_url
      t.text :description
      t.integer :annual_applicants # 연간 응시자 수
      t.float :pass_rate # 평균 합격률
      t.boolean :is_national, default: true # 국가자격/민간자격
      t.boolean :is_active, default: true
      t.json :metadata # 추가 정보 저장용

      t.timestamps
    end

    add_index :certifications, :name
    add_index :certifications, :organization
    add_index :certifications, :category
    add_index :certifications, :is_active
  end
end