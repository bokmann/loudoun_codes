require 'rails_helper'

RSpec.describe SubmissionsController, type: :controller do
  # GET new just displays a view.
  # Use view or request specs

  let!(:contest) { Contest.create }
  let!(:team)    { contest.teams.create }

  describe 'POST create' do
    FIXTURE_NAME = 'Submission.java'

    let(:file) { fixture_file_upload 'files/' + FIXTURE_NAME }
    let(:problem) { contest.problems.create }
    let(:valid_params) { { submission: { attachment: file, problem: problem.id } } }

    it 'rejects submission without file' do
      puts Submission.count
      expect {
        post :create, params: { submission: { problem_id: problem.id } }
      }.not_to change(Submission, :count)

      expect(response).to have_http_status :ok
      expect(flash.alert).not_to be_empty
    end

    it 'rejects submission without problem' do
      expect {
        post :create, params: { submission: { file: file } }
      }.not_to change(Submission, :count)

      expect(response).to have_http_status :ok
      expect(flash.alert).not_to be_empty
    end

    it 'reject submission if contest is not started'
    it 'rejects submission if team not logged in'

    describe 'with valid data' do
      # TODO: Start contest

      it 'creates the Submission' do
        expect {
          post :create, params: valid_params
        }.to change(Submission, :count).by(1)
      end

      let(:submission) { Submission.last }

      after(:each) { submission.attachment.path.delete }

      it 'redirects to show' do
        post :create, params: valid_params
        expect(submission).to be_a Submission
        expect(response).to redirect_to submission_url(submission)
      end

      it 'submits to correct problem' do
        post :create, params: valid_params
        expect(submission.problem).to eq problem
      end

      it 'saves submission file to FS' do
        post :create, params: valid_params

        attachment = submission.attachment
        fixture = file_fixture FIXTURE_NAME

        expect(attachment.path.exist?).to be true

        expect(attachment.path.size).to eq fixture.size
        expect(attachment.with_file('r') { |f| f.read }).to eq fixture.read
      end

      it 'queues submission to be run' do
        expect {
          post :create, params: valid_params
        }.to have_enqueued_job(RunSubmissionJob)
      end

      it 'uses current team'
    end
  end
end
