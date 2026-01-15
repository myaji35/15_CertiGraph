require 'rails_helper'

RSpec.describe UserMastery, type: :model do
  let(:user) { create(:user) }
  let(:knowledge_node) { create(:knowledge_node) }
  let(:mastery) { create(:user_mastery, user: user, knowledge_node: knowledge_node) }

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:mastery_level).is_greater_than_or_equal_to(0.0).is_less_than_or_equal_to(1.0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w(untested learning mastered weak)) }
    it { is_expected.to validate_inclusion_of(:color).in_array(%w(gray green red yellow)) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:knowledge_node) }
  end

  describe '#accuracy' do
    context 'when no attempts' do
      it 'returns 0' do
        mastery = build(:user_mastery, attempts: 0)
        expect(mastery.accuracy).to eq(0.0)
      end
    end

    context 'when has attempts' do
      it 'calculates accuracy percentage' do
        mastery = build(:user_mastery, attempts: 10, correct_attempts: 8)
        expect(mastery.accuracy).to eq(80.0)
      end
    end
  end

  describe '#update_with_attempt' do
    let(:mastery) { create(:user_mastery, :untested) }

    it 'increments attempts' do
      expect {
        mastery.update_with_attempt(correct: true)
      }.to change { mastery.attempts }.by(1)
    end

    it 'increments correct_attempts when correct' do
      expect {
        mastery.update_with_attempt(correct: true)
      }.to change { mastery.correct_attempts }.by(1)
    end

    it 'does not increment correct_attempts when incorrect' do
      expect {
        mastery.update_with_attempt(correct: false)
      }.not_to change { mastery.correct_attempts }
    end

    it 'updates last_tested_at' do
      expect {
        mastery.update_with_attempt(correct: true)
      }.to change { mastery.last_tested_at }
    end

    it 'updates mastery_level' do
      expect {
        mastery.update_with_attempt(correct: true)
      }.to change { mastery.mastery_level }
    end

    it 'adds entry to history' do
      mastery.update_with_attempt(correct: true, time_minutes: 10)
      expect(mastery.history).to be_present
      expect(mastery.history.first['correct']).to be true
      expect(mastery.history.first['time_minutes']).to eq(10)
    end
  end

  describe '#calculate_mastery_level' do
    let(:mastery) { create(:user_mastery, attempts: 10, correct_attempts: 8, mastery_level: 0.5) }

    it 'increases mastery level with more correct attempts' do
      mastery.correct_attempts = 9
      mastery.calculate_mastery_level

      expect(mastery.mastery_level).to be > 0.5
    end

    it 'decreases mastery level with fewer correct attempts' do
      mastery.correct_attempts = 5
      mastery.calculate_mastery_level

      expect(mastery.mastery_level).to be < 0.5
    end
  end

  describe '#update_status' do
    context 'when mastery_level is high' do
      it 'sets status to mastered' do
        mastery.mastery_level = 0.9
        mastery.update_status
        expect(mastery.status).to eq('mastered')
      end
    end

    context 'when mastery_level is medium' do
      it 'sets status to learning' do
        mastery.mastery_level = 0.7
        mastery.update_status
        expect(mastery.status).to eq('learning')
      end
    end

    context 'when mastery_level is low' do
      it 'sets status to weak' do
        mastery.mastery_level = 0.2
        mastery.update_status
        expect(mastery.status).to eq('weak')
      end
    end
  end

  describe '#update_color' do
    context 'when mastery_level is high' do
      it 'sets color to green' do
        mastery.mastery_level = 0.9
        mastery.update_color
        expect(mastery.color).to eq('green')
      end
    end

    context 'when mastery_level is medium' do
      it 'sets color to yellow' do
        mastery.mastery_level = 0.6
        mastery.update_color
        expect(mastery.color).to eq('yellow')
      end
    end

    context 'when mastery_level is low' do
      it 'sets color to red' do
        mastery.mastery_level = 0.2
        mastery.update_color
        expect(mastery.color).to eq('red')
      end
    end
  end

  describe '#recent_accuracy' do
    let(:mastery) { create(:user_mastery) }

    before do
      mastery.history = [
        { timestamp: 3.days.ago.iso8601, correct: true },
        { timestamp: 5.days.ago.iso8601, correct: false },
        { timestamp: 10.days.ago.iso8601, correct: true }
      ]
      mastery.save
    end

    it 'calculates accuracy for recent attempts' do
      accuracy = mastery.recent_accuracy(days: 7)
      expect(accuracy).to eq(50.0) # 2 attempts in 7 days, 1 correct
    end

    it 'excludes old attempts' do
      accuracy = mastery.recent_accuracy(days: 4)
      expect(accuracy).to eq(100.0) # 1 attempt in 4 days, 1 correct
    end
  end

  describe '#days_since_last_test' do
    context 'when tested recently' do
      it 'returns correct number of days' do
        mastery.last_tested_at = 2.days.ago
        days = mastery.days_since_last_test
        expect(days).to eq(2)
      end
    end

    context 'when never tested' do
      it 'returns nil' do
        mastery.last_tested_at = nil
        expect(mastery.days_since_last_test).to be_nil
      end
    end
  end

  describe 'scopes' do
    let!(:mastered) { create(:user_mastery, :mastered, user: user) }
    let!(:weak) { create(:user_mastery, :weak, user: user) }
    let!(:learning) { create(:user_mastery, user: user, status: 'learning') }

    describe '.by_status' do
      it 'filters by status' do
        expect(UserMastery.by_status('mastered')).to include(mastered)
        expect(UserMastery.by_status('weak')).to include(weak)
      end
    end

    describe '.weak_areas' do
      it 'returns only red colored nodes' do
        expect(UserMastery.weak_areas).to include(weak)
        expect(UserMastery.weak_areas).not_to include(mastered)
      end
    end

    describe '.mastered_areas' do
      it 'returns only green colored nodes' do
        expect(UserMastery.mastered_areas).to include(mastered)
        expect(UserMastery.mastered_areas).not_to include(weak)
      end
    end
  end
end
