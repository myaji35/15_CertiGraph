class CertificationMailer < ApplicationMailer
  default from: 'noreply@examsgraph.com'

  # 시험 알림 이메일
  def exam_notification(notification)
    @notification = notification
    @user = notification.user
    @exam_schedule = notification.exam_schedule
    @certification = @exam_schedule.certification

    # 이메일 제목 설정
    subject = case notification.notification_type
              when 'registration_open'
                "#{@certification.name} 원서접수 시작 알림"
              when 'exam_reminder_week'
                "#{@certification.name} 시험 1주일 전 알림"
              when 'exam_reminder_month'
                "#{@certification.name} 시험 1개월 전 알림"
              when 'result_announcement'
                "#{@certification.name} 시험 결과 발표 알림"
              else
                "#{@certification.name} 시험 관련 알림"
              end

    mail(
      to: @user.email,
      subject: subject,
      template_path: 'certification_mailer',
      template_name: 'exam_notification'
    )
  end

  # 원서 접수 시작 알림
  def registration_open_reminder(user, exam_schedule)
    @user = user
    @exam_schedule = exam_schedule
    @certification = exam_schedule.certification
    @registration_url = "https://www.q-net.or.kr" # 실제 원서접수 URL

    mail(
      to: @user.email,
      subject: "[#{@certification.name}] 원서접수가 #{exam_schedule.registration_start_date.strftime('%m월 %d일')} 시작됩니다",
      template_path: 'certification_mailer',
      template_name: 'registration_open_reminder'
    )
  end

  # 시험일 임박 알림
  def exam_day_reminder(user, exam_schedule, days_until)
    @user = user
    @exam_schedule = exam_schedule
    @certification = exam_schedule.certification
    @days_until = days_until
    @exam_date = exam_schedule.exam_date.strftime('%Y년 %m월 %d일')
    @exam_time = exam_schedule.exam_time || "오전 9시"
    @exam_location = exam_schedule.exam_location || "지정 고사장"

    subject = if days_until == 7
                "[#{@certification.name}] 시험 1주일 전입니다"
              elsif days_until == 30
                "[#{@certification.name}] 시험 1개월 전입니다"
              else
                "[#{@certification.name}] 시험 D-#{days_until}"
              end

    mail(
      to: @user.email,
      subject: subject,
      template_path: 'certification_mailer',
      template_name: 'exam_day_reminder'
    )
  end

  # 결과 발표 알림
  def result_announcement(user, exam_schedule)
    @user = user
    @exam_schedule = exam_schedule
    @certification = exam_schedule.certification
    @result_date = exam_schedule.result_date.strftime('%Y년 %m월 %d일')
    @result_url = "https://www.q-net.or.kr/rcv001.do"

    mail(
      to: @user.email,
      subject: "[#{@certification.name}] 시험 결과가 발표되었습니다",
      template_path: 'certification_mailer',
      template_name: 'result_announcement'
    )
  end

  # 다중 시험 일정 요약 (주간/월간 다이제스트)
  def exam_digest(user, period = 'weekly')
    @user = user
    @period = period

    # 관심 자격증 기준 다가오는 시험 일정
    @upcoming_exams = ExamSchedule.joins(:certification)
                                   .where(certifications: { id: user.interested_certification_ids })
                                   .upcoming
                                   .limit(10)

    # 원서 접수 중인 시험
    @open_registrations = ExamSchedule.joins(:certification)
                                       .where(certifications: { id: user.interested_certification_ids })
                                       .open_registration
                                       .limit(5)

    subject_line = period == 'weekly' ? '이번 주 자격증 시험 소식' : '이번 달 자격증 시험 일정'

    mail(
      to: @user.email,
      subject: "[ExamsGraph] #{subject_line}",
      template_path: 'certification_mailer',
      template_name: 'exam_digest'
    )
  end
end