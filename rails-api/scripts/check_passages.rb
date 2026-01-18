#!/usr/bin/env ruby

# Check passage extraction in questions
questions = Question.where(study_material_id: StudyMaterial.where(study_set_id: 9).pluck(:id))

puts "=" * 80
puts "📊 Passage Extraction Analysis"
puts "=" * 80
puts

total = questions.count
with_passage = questions.where.not(passage: nil).where.not(passage: '').count

puts "Total questions: #{total}"
puts "Questions with passage: #{with_passage} (#{(with_passage.to_f / total * 100).round(1)}%)"
puts "Questions without passage: #{total - with_passage}"
puts

puts "=" * 80
puts "📝 Sample Questions (first 5)"
puts "=" * 80
puts

questions.limit(5).each do |q|
  puts "-" * 80
  puts "Q#{q.question_number}: #{q.content.truncate(80)}"
  puts "Topic: #{q.topic}"
  
  if q.passage.present?
    puts "✅ HAS PASSAGE (#{q.passage.length} chars)"
    puts "Preview: #{q.passage.truncate(150)}"
  else
    puts "❌ NO PASSAGE"
  end
  puts
end

puts "=" * 80
puts "🔍 Checking Python parser output format"
puts "=" * 80
puts

# Check if passage is in extraction_metadata
sample = questions.first
if sample.extraction_metadata.present?
  puts "Extraction metadata keys: #{sample.extraction_metadata.keys.join(', ')}"
  if sample.extraction_metadata['passage_items']
    puts "Passage items count: #{sample.extraction_metadata['passage_items']}"
  end
else
  puts "No extraction_metadata found"
end
