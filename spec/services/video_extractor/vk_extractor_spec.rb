describe VideoExtractor::VkExtractor, vcr: { cassette_name: 'vk_extractor' } do
  let(:service) { VideoExtractor::VkExtractor.new url }

  describe 'fetch' do
    subject { service.fetch }

    context 'valid_url' do
      context 'common' do
        let(:url) { 'http://vk.com/video98023184_165811692' }

        its(:hosting) { should eq :vk }
        its(:image_url) { should eq 'http://cs514511.vk.me/u98023184/video/l_81cce630.jpg' }
        its(:player_url) { should eq 'https://vk.com/video_ext.php?oid=98023184&id=165811692&hash=6d9a4c5f93270892' }
      end

      context 'dash' do
        let(:url) { 'http://vk.com/video-42313379_167267838' }
        its(:hosting) { should eq :vk }
      end

      context 'params' do
        let(:url) { 'https://vk.com/video-61933528_167061553?hash=w4ertfg' }
        its(:hosting) { should eq :vk }
      end
    end

    context 'invalid_url' do
      let(:url) { 'http://vk.com/video98023184_165811692zzz' }
      it { should be_nil }
    end

    context 'private_url' do
      let(:url) { 'http://vk.com/video17174270_167070090' }
      it { should be_nil }
    end

    context 'video_with_authorization_url' do
      let(:url) { 'https://vk.com/video-26094363_159977945' }
      it { should be_nil }
    end
  end
end
