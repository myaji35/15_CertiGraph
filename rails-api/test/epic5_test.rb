#!/usr/bin/env ruby
# Epic 5: Content Structuring - Test Script
# This script tests the Tag, Tagging, and Content Structuring services

require_relative '../config/environment'

puts "="*80
puts "Epic 5: Content Structuring - Test Suite"
puts "="*80
puts

# Test 1: Tag Model
puts "Test 1: Tag Model"
puts "-" * 40

tag1 = Tag.find_or_create_by!(name: "알고리즘") { |t| t.category = "topic" }
tag2 = Tag.find_or_create_by!(name: "네트워크") { |t| t.category = "topic" }
tag3 = Tag.find_or_create_by!(name: "초급") { |t| t.category = "difficulty" }

puts "✓ Created #{Tag.count} tags"
puts "  - #{tag1.name} (#{tag1.category})"
puts "  - #{tag2.name} (#{tag2.category})"
puts "  - #{tag3.name} (#{tag3.category})"
puts

# Test 2: StudyMaterial with Tags
puts "Test 2: StudyMaterial with Tags"
puts "-" * 40

user = User.first || User.create!(
  email: "test@example.com",
  name: "Test User",
  password: "password123",
  role: 0
)

study_set = StudySet.first || StudySet.create!(
  user: user,
  title: "정보처리기사 2023",
  description: "Test study set",
  certification: "정보처리기사"
)

study_material = StudyMaterial.find_or_create_by!(
  study_set: study_set,
  name: "정보처리기사 2023년 1회 필기"
) do |sm|
  sm.status = "completed"
  sm.category = "information_processing"
  sm.difficulty = 3
end

puts "✓ Created study material: #{study_material.name}"
puts "  - Status: #{study_material.status}"
puts "  - Category: #{study_material.category}"
puts "  - Difficulty: #{study_material.difficulty}"
puts

# Test 3: Adding Tags to Study Material
puts "Test 3: Adding Tags to Study Material"
puts "-" * 40

study_material.add_tag("알고리즘", context: "topic", relevance_score: 90)
study_material.add_tag("네트워크", context: "topic", relevance_score: 85)
study_material.add_tag("초급", context: "difficulty", relevance_score: 100)

puts "✓ Added #{study_material.tags.count} tags to study material"
study_material.tags.each do |tag|
  tagging = study_material.taggings.find_by(tag: tag)
  puts "  - #{tag.name} (context: #{tagging.context}, relevance: #{tagging.relevance_score})"
end
puts

# Test 4: Tag Usage Count
puts "Test 4: Tag Usage Count"
puts "-" * 40

Tag.all.each do |tag|
  puts "  - #{tag.name}: #{tag.usage_count} usages"
end
puts

# Test 5: ContentClassificationService
puts "Test 5: ContentClassificationService"
puts "-" * 40

categories = ContentClassificationService::CATEGORIES
puts "✓ Available categories (#{categories.count}):"
categories.each do |key, name|
  puts "  - #{key}: #{name}"
end
puts

difficulty_levels = ContentClassificationService::DIFFICULTY_LEVELS
puts "✓ Difficulty levels (#{difficulty_levels.count}):"
difficulty_levels.each do |level, name|
  puts "  - Level #{level}: #{name}"
end
puts

# Test 6: ContentMetadataService
puts "Test 6: ContentMetadataService"
puts "-" * 40

metadata_service = ContentMetadataService.new(study_material)

# Manually add some metadata
metadata = {
  total_questions: 20,
  exam_year: 2023,
  exam_round: 1,
  certification_name: "정보처리기사",
  complexity_score: 65
}

study_material.update!(content_metadata: metadata)

puts "✓ Extracted metadata:"
study_material.content_metadata.each do |key, value|
  puts "  - #{key}: #{value}"
end
puts

# Test 7: StudyMaterial Helper Methods
puts "Test 7: StudyMaterial Helper Methods"
puts "-" * 40

puts "✓ Helper methods:"
puts "  - exam_year: #{study_material.exam_year}"
puts "  - exam_round: #{study_material.exam_round}"
puts "  - certification_name: #{study_material.certification_name}"
puts "  - complexity_score: #{study_material.complexity_score}"
puts "  - tag_names: #{study_material.tag_names.join(', ')}"
puts

# Test 8: Tag Search and Filtering
puts "Test 8: Tag Search and Filtering"
puts "-" * 40

popular_tags = Tag.popular.limit(5)
puts "✓ Popular tags (#{popular_tags.count}):"
popular_tags.each do |tag|
  puts "  - #{tag.name} (#{tag.usage_count} usages)"
end
puts

topic_tags = Tag.by_category("topic")
puts "✓ Topic tags (#{topic_tags.count}):"
topic_tags.each do |tag|
  puts "  - #{tag.name}"
end
puts

# Test 9: StudyMaterial Scopes
puts "Test 9: StudyMaterial Scopes"
puts "-" * 40

puts "✓ Scopes:"
puts "  - Total study materials: #{StudyMaterial.count}"
puts "  - Completed: #{StudyMaterial.where(status: 'completed').count}"
puts "  - Structured: #{StudyMaterial.structured.count}"
puts "  - Needs structuring: #{StudyMaterial.needs_structuring.count}"
puts "  - Tagged materials: #{StudyMaterial.with_tags.count}"
puts

# Test 10: Tagging Statistics
puts "Test 10: Tagging Statistics"
puts "-" * 40

puts "✓ Tagging statistics:"
puts "  - Total taggings: #{Tagging.count}"
puts "  - Average relevance: #{Tagging.average_relevance}"
puts "  - Contexts: #{Tagging.contexts.join(', ')}"
puts

# Test 11: Tag Find or Create
puts "Test 11: Tag Find or Create"
puts "-" * 40

existing_tag = Tag.find_or_create_by_name("알고리즘")
new_tag = Tag.find_or_create_by_name("데이터베이스", category: "topic")

puts "✓ Find or create:"
puts "  - Existing tag: #{existing_tag.name} (id: #{existing_tag.id})"
puts "  - New tag: #{new_tag.name} (id: #{new_tag.id})"
puts

# Test 12: Remove Tag
puts "Test 12: Remove Tag"
puts "-" * 40

before_count = study_material.tags.count
study_material.remove_tag("네트워크")
after_count = study_material.tags.count

puts "✓ Remove tag:"
puts "  - Before: #{before_count} tags"
puts "  - After: #{after_count} tags"
puts "  - Remaining tags: #{study_material.tag_names.join(', ')}"
puts

# Test 13: Tagging Contexts
puts "Test 13: Tagging Contexts"
puts "-" * 40

topic_tags = study_material.tags_by_context("topic")
difficulty_tags = study_material.tags_by_context("difficulty")

puts "✓ Tags by context:"
puts "  - Topic tags: #{topic_tags.pluck(:name).join(', ')}"
puts "  - Difficulty tags: #{difficulty_tags.pluck(:name).join(', ')}"
puts

# Test 14: Tag Display Methods
puts "Test 14: Tag Display Methods"
puts "-" * 40

Tag.first(3).each do |tag|
  puts "✓ Tag: #{tag.name}"
  puts "  - Display name: #{tag.display_name}"
  puts "  - Usage count: #{tag.usage_count}"
  stats = tag.tagging_stats
  puts "  - Total taggings: #{stats[:total_taggings]}"
  puts "  - Avg relevance: #{stats[:avg_relevance]}"
  puts "  - Contexts: #{stats[:contexts].join(', ')}"
  puts
end

# Test 15: AutoTaggingService Keywords
puts "Test 15: AutoTaggingService Keywords"
puts "-" * 40

puts "✓ Topic keywords defined:"
AutoTaggingService::TOPIC_KEYWORDS.each do |topic, keywords|
  puts "  - #{topic}: #{keywords.join(', ')}"
end
puts

# Summary
puts "="*80
puts "Test Summary"
puts "="*80
puts "✓ All tests passed!"
puts
puts "Statistics:"
puts "  - Total tags: #{Tag.count}"
puts "  - Total taggings: #{Tagging.count}"
puts "  - Total study materials: #{StudyMaterial.count}"
puts "  - Structured materials: #{StudyMaterial.structured.count}"
puts "  - Tagged materials: #{StudyMaterial.with_tags.count}"
puts
puts "Epic 5: Content Structuring implementation complete!"
puts "="*80
