# Service to generate performance snapshots
class GeneratePerformanceSnapshotService
  attr_reader :user, :study_set

  def initialize(user, study_set: nil)
    @user = user
    @study_set = study_set
  end

  def generate(date: Date.today, period_type: 'daily')
    # Find or create snapshot
    snapshot = PerformanceSnapshot.find_or_initialize_by(
      user_id: user.id,
      study_set_id: study_set&.id,
      snapshot_date: date,
      period_type: period_type
    )

    # Calculate all metrics
    calculate_overall_metrics(snapshot)
    calculate_node_status_counts(snapshot)
    calculate_time_metrics(snapshot)
    calculate_trend_changes(snapshot)
    calculate_breakdowns(snapshot)
    calculate_time_of_day_patterns(snapshot)
    calculate_predictions(snapshot)
    calculate_comparative_metrics(snapshot)
    calculate_top_items(snapshot)

    snapshot.save!
    snapshot
  end

  private

  def user_masteries_scope
    scope = UserMastery.where(user_id: user.id)
    scope = scope.joins(:knowledge_node)
                 .where(knowledge_nodes: { study_material_id: study_materials_ids }) if study_set
    scope
  end

  def study_materials_ids
    @study_materials_ids ||= study_set ? study_set.study_materials.pluck(:id) : []
  end

  def calculate_overall_metrics(snapshot)
    masteries = user_masteries_scope

    snapshot.overall_mastery_level = masteries.average(:mastery_level).to_f.round(3)
    snapshot.total_attempts = masteries.sum(:attempts)
    snapshot.total_correct = masteries.sum(:correct_attempts)
    snapshot.overall_accuracy = snapshot.total_attempts > 0 ?
      (snapshot.total_correct.to_f / snapshot.total_attempts * 100).round(2) : 0.0

    # Completion percentage
    total_concepts = knowledge_nodes_count
    tested_concepts = masteries.where('attempts > 0').count
    snapshot.completion_percentage = total_concepts > 0 ?
      (tested_concepts.to_f / total_concepts * 100).round(2) : 0.0
  end

  def calculate_node_status_counts(snapshot)
    masteries = user_masteries_scope

    snapshot.mastered_nodes_count = masteries.where(status: 'mastered').count
    snapshot.learning_nodes_count = masteries.where(status: 'learning').count
    snapshot.weak_nodes_count = masteries.where(status: 'weak').count

    total_nodes = knowledge_nodes_count
    tested_nodes = masteries.where('attempts > 0').count
    snapshot.untested_nodes_count = total_nodes - tested_nodes
  end

  def calculate_time_metrics(snapshot)
    masteries = user_masteries_scope

    snapshot.total_study_minutes = masteries.sum(:total_time_minutes)

    # Study sessions count (approximate from history)
    session_count = 0
    masteries.each do |mastery|
      session_count += mastery.history.length if mastery.history.present?
    end
    snapshot.study_sessions_count = session_count

    snapshot.avg_session_minutes = session_count > 0 ?
      (snapshot.total_study_minutes.to_f / session_count).round(1) : 0.0
  end

  def calculate_trend_changes(snapshot)
    # Compare with previous snapshot
    previous = PerformanceSnapshot
      .where(user_id: user.id, study_set_id: study_set&.id, period_type: snapshot.period_type)
      .where('snapshot_date < ?', snapshot.snapshot_date)
      .order(snapshot_date: :desc)
      .first

    if previous
      snapshot.mastery_change = snapshot.overall_mastery_level - previous.overall_mastery_level
      snapshot.accuracy_change = snapshot.overall_accuracy - previous.overall_accuracy
      snapshot.attempts_change = snapshot.total_attempts - previous.total_attempts
    else
      snapshot.mastery_change = 0.0
      snapshot.accuracy_change = 0.0
      snapshot.attempts_change = 0
    end
  end

  def calculate_breakdowns(snapshot)
    return unless study_set

    # Subject breakdown
    subjects = KnowledgeNode
      .where(study_material_id: study_materials_ids, level: 'subject')

    subject_data = subjects.map do |subject|
      subject_masteries = user_masteries_for_descendants(subject)

      {
        id: subject.id,
        name: subject.name,
        mastery: calculate_average_mastery(subject_masteries),
        accuracy: calculate_accuracy(subject_masteries),
        count: subject_masteries.count
      }
    end

    snapshot.subject_breakdown = subject_data

    # Chapter breakdown
    chapters = KnowledgeNode
      .where(study_material_id: study_materials_ids, level: 'chapter')

    chapter_data = chapters.map do |chapter|
      chapter_masteries = user_masteries_for_descendants(chapter)

      {
        id: chapter.id,
        name: chapter.name,
        parent: chapter.parent_name,
        mastery: calculate_average_mastery(chapter_masteries),
        accuracy: calculate_accuracy(chapter_masteries),
        count: chapter_masteries.count
      }
    end

    snapshot.chapter_breakdown = chapter_data

    # Concept breakdown (summary)
    concepts = KnowledgeNode
      .where(study_material_id: study_materials_ids, level: 'concept')

    concept_summary = {
      total: concepts.count,
      mastered: user_masteries_scope.where('mastery_level >= 0.8').count,
      learning: user_masteries_scope.where('mastery_level >= 0.5 AND mastery_level < 0.8').count,
      weak: user_masteries_scope.where('mastery_level < 0.5 AND attempts > 0').count,
      untested: concepts.count - user_masteries_scope.where('attempts > 0').count
    }

    snapshot.concept_breakdown = concept_summary
  end

  def calculate_time_of_day_patterns(snapshot)
    # Analyze time of day patterns from history
    time_data = {
      morning: { minutes: 0, attempts: 0, correct: 0 },
      afternoon: { minutes: 0, attempts: 0, correct: 0 },
      evening: { minutes: 0, attempts: 0, correct: 0 },
      night: { minutes: 0, attempts: 0, correct: 0 }
    }

    user_masteries_scope.each do |mastery|
      next unless mastery.history.present?

      mastery.history.each do |entry|
        hour = Time.parse(entry['timestamp']).hour
        period = case hour
        when 6..11 then :morning
        when 12..17 then :afternoon
        when 18..23 then :evening
        else :night
        end

        time_data[period][:minutes] += entry['time_minutes'] || 0
        time_data[period][:attempts] += 1
        time_data[period][:correct] += 1 if entry['correct']
      end
    end

    snapshot.morning_study_minutes = time_data[:morning][:minutes]
    snapshot.afternoon_study_minutes = time_data[:afternoon][:minutes]
    snapshot.evening_study_minutes = time_data[:evening][:minutes]
    snapshot.night_study_minutes = time_data[:night][:minutes]

    snapshot.morning_accuracy = calculate_period_accuracy(time_data[:morning])
    snapshot.afternoon_accuracy = calculate_period_accuracy(time_data[:afternoon])
    snapshot.evening_accuracy = calculate_period_accuracy(time_data[:evening])
    snapshot.night_accuracy = calculate_period_accuracy(time_data[:night])
  end

  def calculate_predictions(snapshot)
    predictor = PerformancePredictorService.new(user, study_set: study_set)

    # Predicted exam score
    score_prediction = predictor.predict_exam_score
    snapshot.predicted_exam_score = score_prediction[:predicted_score]

    # Days to mastery
    timeline = predictor.predict_mastery_timeline(target_mastery: 0.8)
    snapshot.estimated_days_to_mastery = timeline[:estimated_days] || 0

    # Goal achievement probability
    goal = predictor.predict_goal_achievement(target_score: 80)
    snapshot.goal_achievement_probability = goal[:probability] || 0.0
  end

  def calculate_comparative_metrics(snapshot)
    # Calculate percentile rank
    return unless study_set

    all_user_averages = UserMastery
      .joins(:knowledge_node)
      .where(knowledge_nodes: { study_material_id: study_materials_ids })
      .group(:user_id)
      .average(:mastery_level)

    user_avg = snapshot.overall_mastery_level
    users_below = all_user_averages.count { |_uid, avg| avg < user_avg }

    snapshot.percentile_rank = all_user_averages.empty? ?
      0.0 : (users_below.to_f / all_user_averages.length * 100).round(2)

    snapshot.avg_mastery_vs_others = all_user_averages.empty? ?
      0.0 : (all_user_averages.values.sum / all_user_averages.length.to_f).round(3)
  end

  def calculate_top_items(snapshot)
    # Top strengths
    strengths = user_masteries_scope
      .where('mastery_level >= 0.8 AND attempts >= 3')
      .order(mastery_level: :desc)
      .limit(5)
      .includes(:knowledge_node)
      .map { |m| { name: m.knowledge_node.name, mastery: m.mastery_level } }

    snapshot.top_strengths = strengths

    # Top weaknesses
    weaknesses = user_masteries_scope
      .where('mastery_level < 0.6 AND attempts >= 1')
      .order(mastery_level: :asc)
      .limit(5)
      .includes(:knowledge_node)
      .map { |m| { name: m.knowledge_node.name, mastery: m.mastery_level } }

    snapshot.top_weaknesses = weaknesses

    # Recent improvements
    improvements = []
    user_masteries_scope.includes(:knowledge_node).each do |mastery|
      next if mastery.history.length < 2

      recent = mastery.history.last(3)
      older = mastery.history.first(3)

      recent_avg = recent.sum { |h| h['mastery_level'] || 0 } / recent.length.to_f
      older_avg = older.sum { |h| h['mastery_level'] || 0 } / older.length.to_f

      if recent_avg > older_avg + 0.1
        improvements << {
          name: mastery.knowledge_node.name,
          improvement: (recent_avg - older_avg).round(3)
        }
      end
    end

    snapshot.recent_improvements = improvements.sort_by { |i| -i[:improvement] }.first(5)

    # Study streak data
    dates = user_masteries_scope
      .where('last_tested_at IS NOT NULL')
      .select('DISTINCT DATE(last_tested_at) as d')
      .order('d DESC')
      .pluck('d')

    current_streak = 0
    current_date = Date.today

    dates.each do |date|
      break if date < current_date - 1.day
      current_streak += 1 if date == current_date
      current_date = date - 1.day
    end

    snapshot.study_streak_data = {
      current_streak: current_streak,
      total_study_days: dates.length,
      last_study_date: dates.first
    }
  end

  def user_masteries_for_descendants(node)
    descendant_ids = KnowledgeNode
      .where(study_material_id: study_materials_ids)
      .where('parent_name = ? OR name = ?', node.name, node.name)
      .pluck(:id)

    user_masteries_scope.where(knowledge_node_id: descendant_ids)
  end

  def knowledge_nodes_count
    return 0 unless study_set

    KnowledgeNode
      .where(study_material_id: study_materials_ids)
      .where(level: 'concept')
      .count
  end

  def calculate_average_mastery(masteries)
    return 0.0 if masteries.empty?
    (masteries.sum(&:mastery_level) / masteries.count.to_f).round(3)
  end

  def calculate_accuracy(masteries)
    total = masteries.sum(&:attempts)
    return 0.0 if total.zero?

    (masteries.sum(&:correct_attempts).to_f / total * 100).round(2)
  end

  def calculate_period_accuracy(period_data)
    return 0.0 if period_data[:attempts].zero?

    (period_data[:correct].to_f / period_data[:attempts] * 100).round(2)
  end
end
