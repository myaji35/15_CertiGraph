require 'test_helper'

class ProcessPdfJobTest < ActiveJob::TestCase
  setup do
    @study_material = study_materials(:one)
  end

  test "enqueues ProcessPdfJob on correct queue" do
    assert_enqueued_with(job: ProcessPdfJob, queue: 'pdf_processing') do
      ProcessPdfJob.perform_later(@study_material.id)
    end
  end

  test "ProcessPdfJob has correct queue_as" do
    job = ProcessPdfJob.new
    assert_equal 'pdf_processing', job.queue_name
  end

  test "enqueues GenerateEmbeddingJob for each question" do
    # Study Material 준비
    @study_material.pdf_file.attach(fixture_file_upload('sample.pdf'))

    assert_enqueued_jobs 1, only: ProcessPdfJob do
      ProcessPdfJob.perform_now(@study_material.id)
    end
  end
end
