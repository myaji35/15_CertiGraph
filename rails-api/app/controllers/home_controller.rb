class HomeController < ApplicationController
  def index
    @stats = {
      users: 1000,
      questions: 50000,
      success_rate: 95
    }

    @recent_exams = [
      {
        title: "2024 사회복지사 1급 기출",
        category: "최신 기출문제 모음집",
        questions: 1234
      },
      {
        title: "정신건강론 핵심문제",
        category: "핵심 개념 정리 문제집",
        questions: 567
      },
      {
        title: "사회복지정책론 모의고사",
        category: "실전 모의고사 200문제",
        questions: 756
      }
    ]
  end

  def signin
  end

  def signup
  end
end