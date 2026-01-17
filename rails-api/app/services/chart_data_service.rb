# app/services/chart_data_service.rb
class ChartDataService
  def initialize(user)
    @user = user
    @analytics = ProgressAnalyticsService.new(user)
  end

  # 1. Line Chart - Performance Trend Over Time
  def performance_line_chart(period: 'month')
    case period
    when 'week'
      data = last_n_days(7)
    when 'month'
      data = last_n_days(30)
    when 'year'
      data = last_n_months(12)
    else
      data = last_n_days(30)
    end

    {
      type: 'line',
      data: {
        labels: data.map { |d| d[:label] },
        datasets: [
          {
            label: 'Score',
            data: data.map { |d| d[:score] },
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.2)',
            tension: 0.4,
            fill: true
          },
          {
            label: 'Questions Answered',
            data: data.map { |d| d[:questions] },
            borderColor: 'rgb(153, 102, 255)',
            backgroundColor: 'rgba(153, 102, 255, 0.2)',
            tension: 0.4,
            fill: false,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        interaction: {
          mode: 'index',
          intersect: false
        },
        plugins: {
          title: {
            display: true,
            text: 'Performance Trend'
          },
          tooltip: {
            callbacks: {
              label: ->(context) { "#{context.dataset.label}: #{context.parsed.y}" }
            }
          }
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: { display: true, text: 'Score (%)' }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: { display: true, text: 'Questions' },
            grid: { drawOnChartArea: false }
          }
        }
      }
    }
  end

  # 2. Bar Chart - Subject Performance
  def subject_bar_chart
    study_sets = @user.study_sets.includes(:test_sessions)

    data = study_sets.map do |study_set|
      sessions = study_set.test_sessions.where(user: @user, status: 'completed')
      {
        label: study_set.title,
        score: sessions.average(:score)&.round(2) || 0,
        count: sessions.count
      }
    end

    {
      type: 'bar',
      data: {
        labels: data.map { |d| d[:label] },
        datasets: [
          {
            label: 'Average Score',
            data: data.map { |d| d[:score] },
            backgroundColor: data.map { |d| score_color(d[:score]) },
            borderColor: data.map { |d| score_border_color(d[:score]) },
            borderWidth: 2
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Performance by Subject'
          },
          legend: {
            display: true,
            position: 'top'
          },
          tooltip: {
            callbacks: {
              afterLabel: ->(context) { "Tests: #{data[context.dataIndex][:count]}" }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            title: { display: true, text: 'Score (%)' }
          }
        }
      }
    }
  end

  # 3. Radar Chart - Capability Analysis
  def capability_radar_chart
    masteries = @user.user_masteries.joins(:knowledge_node).group('knowledge_nodes.category')

    categories = masteries.pluck('knowledge_nodes.category').uniq.compact
    return empty_radar if categories.empty?

    data = categories.map do |category|
      category_masteries = @user.user_masteries.joins(:knowledge_node)
                                .where('knowledge_nodes.category': category)
      total = category_masteries.count
      mastered = category_masteries.where(status: 'mastered').count

      total.zero? ? 0 : ((mastered.to_f / total) * 100).round(2)
    end

    {
      type: 'radar',
      data: {
        labels: categories,
        datasets: [
          {
            label: 'Mastery Level',
            data: data,
            backgroundColor: 'rgba(54, 162, 235, 0.2)',
            borderColor: 'rgb(54, 162, 235)',
            pointBackgroundColor: 'rgb(54, 162, 235)',
            pointBorderColor: '#fff',
            pointHoverBackgroundColor: '#fff',
            pointHoverBorderColor: 'rgb(54, 162, 235)'
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Capability Analysis by Category'
          }
        },
        scales: {
          r: {
            beginAtZero: true,
            max: 100,
            ticks: {
              stepSize: 20
            }
          }
        }
      }
    }
  end

  # 4. Doughnut Chart - Progress Distribution
  def progress_doughnut_chart
    overview = @analytics.overview[:mastery_overview]

    {
      type: 'doughnut',
      data: {
        labels: ['Mastered', 'Learning', 'Weak', 'Untested'],
        datasets: [
          {
            data: [
              overview[:mastered],
              overview[:learning],
              overview[:weak],
              overview[:untested]
            ],
            backgroundColor: [
              'rgba(75, 192, 192, 0.8)',
              'rgba(54, 162, 235, 0.8)',
              'rgba(255, 99, 132, 0.8)',
              'rgba(201, 203, 207, 0.8)'
            ],
            borderColor: [
              'rgb(75, 192, 192)',
              'rgb(54, 162, 235)',
              'rgb(255, 99, 132)',
              'rgb(201, 203, 207)'
            ],
            borderWidth: 2
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Knowledge Mastery Distribution'
          },
          legend: {
            position: 'bottom'
          },
          tooltip: {
            callbacks: {
              label: ->(context) {
                label = context.label || ''
                value = context.parsed || 0
                total = context.dataset.data.reduce(:+)
                percentage = ((value / total) * 100).round(1)
                "#{label}: #{value} (#{percentage}%)"
              }
            }
          }
        }
      }
    }
  end

  # 5. Scatter Chart - Difficulty vs Accuracy
  def difficulty_accuracy_scatter
    sessions = @user.test_sessions.where(status: 'completed').includes(:test_questions)

    data_points = sessions.map do |session|
      accuracy = session.total_answered.zero? ? 0 : (session.correct_answers.to_f / session.total_answered * 100)
      avg_difficulty = session.test_questions.average(:difficulty_level) || 5

      {
        x: avg_difficulty,
        y: accuracy.round(2),
        label: session.created_at.strftime('%m/%d'),
        session_id: session.id
      }
    end

    {
      type: 'scatter',
      data: {
        datasets: [
          {
            label: 'Test Sessions',
            data: data_points.map { |p| { x: p[:x], y: p[:y] } },
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgb(255, 99, 132)',
            pointRadius: 6,
            pointHoverRadius: 8
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Difficulty vs Accuracy'
          },
          tooltip: {
            callbacks: {
              label: ->(context) {
                point = data_points[context.dataIndex]
                "#{point[:label]}: Difficulty #{point[:x]}, Accuracy #{point[:y]}%"
              }
            }
          }
        },
        scales: {
          x: {
            type: 'linear',
            position: 'bottom',
            title: { display: true, text: 'Difficulty Level (1-10)' },
            min: 0,
            max: 10
          },
          y: {
            title: { display: true, text: 'Accuracy (%)' },
            min: 0,
            max: 100
          }
        }
      }
    }
  end

  # 6. Heatmap - Study Activity by Time
  def activity_heatmap_chart(weeks: 12)
    end_date = Date.current
    start_date = end_date - weeks.weeks

    sessions = @user.test_sessions.where(created_at: start_date..end_date)

    data = []
    (start_date..end_date).each do |date|
      day_sessions = sessions.select { |s| s.created_at.to_date == date }
      data << {
        date: date.to_s,
        day: date.strftime('%A'),
        week: date.cweek,
        count: day_sessions.count,
        minutes: day_sessions.sum { |s|
          next 0 unless s.started_at && s.completed_at
          ((s.completed_at - s.started_at) / 60).round
        }
      }
    end

    # Transform to matrix format
    matrix_data = []
    data.group_by { |d| d[:week] }.each do |week, days|
      (0..6).each do |day_index|
        day_data = days.find { |d| d[:date].to_date.wday == day_index } ||
                   { count: 0, minutes: 0 }
        matrix_data << {
          x: week,
          y: day_index,
          v: day_data[:count],
          minutes: day_data[:minutes]
        }
      end
    end

    {
      type: 'matrix',
      data: {
        datasets: [
          {
            label: 'Study Sessions',
            data: matrix_data,
            backgroundColor: ->(context) {
              value = context.raw[:v]
              if value === 0
                'rgba(200, 200, 200, 0.1)'
              elsif value < 3
                'rgba(75, 192, 192, 0.3)'
              elsif value < 6
                'rgba(75, 192, 192, 0.6)'
              else
                'rgba(75, 192, 192, 0.9)'
              end
            },
            borderColor: 'rgba(0, 0, 0, 0.1)',
            borderWidth: 1,
            width: ->(context) { (context.chart.chartArea || {}).width / weeks - 2 },
            height: ->(context) { (context.chart.chartArea || {}).height / 7 - 2 }
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Study Activity Heatmap (Last 12 Weeks)'
          },
          tooltip: {
            callbacks: {
              title: ->() { '' },
              label: ->(context) {
                v = context.raw
                days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                "#{days[v[:y]]}, Week #{v[:x]}: #{v[:v]} sessions (#{v[:minutes]} min)"
              }
            }
          },
          legend: {
            display: false
          }
        },
        scales: {
          x: {
            type: 'linear',
            position: 'bottom',
            title: { display: true, text: 'Week of Year' },
            ticks: {
              stepSize: 1
            }
          },
          y: {
            type: 'linear',
            offset: true,
            title: { display: true, text: 'Day of Week' },
            ticks: {
              stepSize: 1,
              callback: ->(value) { ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][value] }
            }
          }
        }
      }
    }
  end

  # 7. Area Chart - Cumulative Learning Progress
  def cumulative_progress_area_chart
    sessions = @user.test_sessions.where(status: 'completed').order(:created_at)

    cumulative_data = []
    cumulative_questions = 0
    cumulative_correct = 0
    cumulative_hours = 0

    sessions.each do |session|
      cumulative_questions += session.total_answered
      cumulative_correct += session.correct_answers
      if session.started_at && session.completed_at
        cumulative_hours += ((session.completed_at - session.started_at) / 3600)
      end

      cumulative_data << {
        date: session.created_at.strftime('%m/%d'),
        questions: cumulative_questions,
        correct: cumulative_correct,
        hours: cumulative_hours.round(1),
        accuracy: cumulative_questions.zero? ? 0 : ((cumulative_correct.to_f / cumulative_questions) * 100).round(1)
      }
    end

    {
      type: 'line',
      data: {
        labels: cumulative_data.map { |d| d[:date] },
        datasets: [
          {
            label: 'Total Questions',
            data: cumulative_data.map { |d| d[:questions] },
            backgroundColor: 'rgba(54, 162, 235, 0.3)',
            borderColor: 'rgb(54, 162, 235)',
            fill: true,
            tension: 0.4
          },
          {
            label: 'Correct Answers',
            data: cumulative_data.map { |d| d[:correct] },
            backgroundColor: 'rgba(75, 192, 192, 0.3)',
            borderColor: 'rgb(75, 192, 192)',
            fill: true,
            tension: 0.4
          },
          {
            label: 'Study Hours',
            data: cumulative_data.map { |d| d[:hours] },
            backgroundColor: 'rgba(255, 159, 64, 0.3)',
            borderColor: 'rgb(255, 159, 64)',
            fill: true,
            tension: 0.4,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        interaction: {
          mode: 'index',
          intersect: false
        },
        plugins: {
          title: {
            display: true,
            text: 'Cumulative Learning Progress'
          },
          tooltip: {
            callbacks: {
              afterBody: ->(items) {
                index = items[0].dataIndex
                data = cumulative_data[index]
                "Accuracy: #{data[:accuracy]}%"
              }
            }
          }
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: { display: true, text: 'Questions' },
            beginAtZero: true
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: { display: true, text: 'Hours' },
            grid: { drawOnChartArea: false },
            beginAtZero: true
          }
        }
      }
    }
  end

  # Composite dashboard with all charts
  def all_charts
    {
      performance_line: performance_line_chart,
      subject_bar: subject_bar_chart,
      capability_radar: capability_radar_chart,
      progress_doughnut: progress_doughnut_chart,
      difficulty_scatter: difficulty_accuracy_scatter,
      activity_heatmap: activity_heatmap_chart,
      cumulative_area: cumulative_progress_area_chart
    }
  end

  private

  def last_n_days(n)
    (0...n).map do |i|
      date = Date.current - i.days
      sessions = @user.test_sessions.where('DATE(created_at) = ?', date).where(status: 'completed')

      {
        label: date.strftime('%m/%d'),
        score: sessions.average(:score)&.round(2) || 0,
        questions: sessions.sum(:total_answered)
      }
    end.reverse
  end

  def last_n_months(n)
    (0...n).map do |i|
      date = Date.current - i.months
      start_date = date.beginning_of_month
      end_date = date.end_of_month
      sessions = @user.test_sessions.where(created_at: start_date..end_date).where(status: 'completed')

      {
        label: date.strftime('%b %y'),
        score: sessions.average(:score)&.round(2) || 0,
        questions: sessions.sum(:total_answered)
      }
    end.reverse
  end

  def score_color(score)
    case score
    when 90..100 then 'rgba(75, 192, 192, 0.8)'
    when 70..89 then 'rgba(54, 162, 235, 0.8)'
    when 50..69 then 'rgba(255, 206, 86, 0.8)'
    else 'rgba(255, 99, 132, 0.8)'
    end
  end

  def score_border_color(score)
    case score
    when 90..100 then 'rgb(75, 192, 192)'
    when 70..89 then 'rgb(54, 162, 235)'
    when 50..69 then 'rgb(255, 206, 86)'
    else 'rgb(255, 99, 132)'
    end
  end

  def empty_radar
    {
      type: 'radar',
      data: {
        labels: ['No Data'],
        datasets: [
          {
            label: 'No Data Available',
            data: [0],
            backgroundColor: 'rgba(201, 203, 207, 0.2)',
            borderColor: 'rgb(201, 203, 207)'
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'No category data available'
          }
        }
      }
    }
  end
end
