describe Moderations::AnimeVideoReportsController do
  before { sign_in moderator }

  let(:user) { create :user, :user }
  let(:moderator) { create :user, :video_moderator }
  let(:anime_video) { create :anime_video, anime: create(:anime) }
  let!(:anime_video_report) { create :anime_video_report, user: user, kind: kind, anime_video: anime_video }
  let(:kind) { 'broken' }

  describe '#index' do
    before { get :index }
    it { expect(response).to have_http_status :success }
  end

  describe '#accept' do
    before { get :accept, id: anime_video_report.id }

    context 'broken' do
      it do
        expect(response).to redirect_to moderations_anime_video_reports_url
        expect(anime_video.reload.state).to eq kind
      end
    end

    context 'wrong' do
      let(:kind) { 'wrong' }
      it do
        expect(response).to redirect_to moderations_anime_video_reports_url
        expect(anime_video.reload.state).to eq kind
      end
    end
  end

  describe '#accept_edit' do
    before { get :accept_edit, id: anime_video_report.id }
    it do
      expect(anime_video_report.reload).to be_accepted
      expect(anime_video.reload.state).to eq kind
    end
  end

  describe '#create' do
    let(:anime_video_report) {}
    let(:params) do
      {
        kind: 'broken',
        anime_video_id: anime_video.id,
        user_id: user.id,
        message: 'test'
      }
    end
    before { post :create, anime_video_report: params }

    it do
      expect(response).to have_http_status :success
      expect(resource).to be_persisted
      expect(resource).to have_attributes params
    end
  end

  describe '#cancel' do
    let(:anime_video) { create :anime_video, anime: create(:anime), state: state }
    let!(:anime_video_report) { create :anime_video_report, user: user, kind: kind, anime_video: anime_video, state: 'accepted' }
    let(:state) { kind }

    before { get :cancel, id: anime_video_report.id }

    context 'broken' do
      let(:kind) { 'broken' }
      it do
        expect(response).to redirect_to moderations_anime_video_reports_url
        expect(anime_video.reload).to be_working
      end
    end

    context 'wrong' do
      let(:kind) { 'wrong' }
      it do
        expect(response).to redirect_to moderations_anime_video_reports_url
        expect(anime_video.reload).to be_working
      end
    end

    context 'uploaded' do
      let(:kind) { 'uploaded' }
      it { expect(response).to redirect_to moderations_anime_video_reports_url }

      context 'rejected' do
        let(:state) { 'rejected' }
        it { expect(anime_video.reload).to be_uploaded }
      end

      context 'rejected' do
        let(:state) { 'working' }
        it { expect(anime_video.reload).to be_uploaded }
      end
    end
  end

  describe '#reject' do
    before { get :reject, id: anime_video_report.id }

    context 'broken' do
      let(:kind) { 'broken' }
      it do
        expect(response).to redirect_to moderations_anime_video_reports_url
        expect(anime_video.reload.state).to eq 'working'
      end
    end

    context 'wrong' do
      let(:kind) { 'wrong' }
      it do
        expect(response).to redirect_to moderations_anime_video_reports_url
        expect(anime_video.reload.state).to eq 'working'
      end
    end
  end
end
