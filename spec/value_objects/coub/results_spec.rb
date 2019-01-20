describe Coub::Results do
  let(:coub_results) { Coub::Results.new coubs: coubs, iterator: iterator }
  let(:coubs) { [] }
  let(:iterator) { 'zxc' }

  describe '#encrypted_iterator' do
    it { expect(Encryptor.instance.decrypt(coub_results.encrypted_iterator)).to eq iterator }
  end
end