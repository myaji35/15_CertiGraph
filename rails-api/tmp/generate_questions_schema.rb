conn = ActiveRecord::Base.connection
columns = conn.columns(:questions)

puts '  create_table "questions", force: :cascade do |t|'
columns.each do |col|
  next if col.name == 'id'

  type = case col.sql_type
  when /vector/i then 'text'
  when /TEXT/i then 'text'
  when /INTEGER/i then 'integer'
  when /datetime/i then 'datetime'
  when /boolean/i then 'boolean'
  when /float/i then 'float'
  when /json/i then 'json'
  when /varchar/i then 'string'
  else col.type.to_s
  end

  line = "    t.#{type} \"#{col.name}\""
  line += ', null: false' unless col.null
  puts line
end
puts '    t.timestamps'
puts '  end'
puts ''
puts '  add_index "questions", ["study_material_id"], name: "index_questions_on_study_material_id"'
puts '  add_index "questions", ["study_material_id", "question_number"], name: "index_questions_on_study_material_id_and_question_number", unique: true'
puts '  add_index "questions", ["question_number"], name: "index_questions_on_question_number"'
puts '  add_index "questions", ["question_type"], name: "index_questions_on_question_type"'
puts '  add_index "questions", ["validation_status"], name: "index_questions_on_validation_status"'
puts '  add_index "questions", ["topic"], name: "index_questions_on_topic"'
puts '  add_index "questions", ["difficulty"], name: "index_questions_on_difficulty"'
