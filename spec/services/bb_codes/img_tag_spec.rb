describe BbCodes::ImgTag do
  let(:tag) { BbCodes::ImgTag.instance }
  let(:text_hash) { 'hash' }

  describe 'format' do
    subject { tag.format text, text_hash }
    let(:url) { 'http://site.com/site-url' }
    let(:text) { "[img]#{url}[/img]" }

    context 'common_case' do
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\" /></a>" }
    end

    context 'multiple_images' do
      let(:url_2) { 'http://site.com/site-url-2' }
      let(:text) { "[img]#{url}[/img] [img]#{url_2}[/img]" }
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\" /></a> <a href=\"#{url_2}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url_2}\" /></a>" }
    end

    context 'with_sizes' do
      let(:text) { "[img 400x500]#{url}[/img]" }
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\"  width=\"400\" height=\"500\"/></a>" }
    end

    context 'with_width' do
      let(:text) { "[img w=400]#{url}[/img]" }
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\"  width=\"400\"/></a>" }
    end

    context 'with_height' do
      let(:text) { "[img h=500]#{url}[/img]" }
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\"  height=\"500\"/></a>" }
    end

    context 'with width&height' do
      let(:text) { "[img width=400 height=500]#{url}[/img]" }
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\"  width=\"400\" height=\"500\"/></a>" }
    end

    context 'with_class' do
      let(:text) { "[img class=zxc]#{url}[/img]" }
      it { should eq "<a href=\"#{url}\" rel=\"#{text_hash}\" class=\"b-image unprocessed\">
<img src=\"#{url}\" class=\"zxc\"/></a>" }
    end

    context 'inside_url' do
      let(:link) { '/test' }
      let(:text) { "[url=#{link}][img]#{url}[/img][/url]" }
      it { should eq "[url=#{link}]<img src=\"#{url}\" class=\"check-width\"/>[/url]" }
    end
  end
end
