require 'spec_helper'

describe AkamaiRSpec::Response do
  let(:response) { double(Net::HTTPResponse) }
  subject { described_class.new(response) }

  describe '#headers' do
    before do
      expect(response).to receive(:to_hash).and_return(headers)
    end

    context 'headers are empty' do
      let(:headers) { {} }
      it 'returns a hash' do
        expect(subject.headers).to be_a(Hash)
      end
    end

    context 'header value is a single element array' do
      let(:headers) { {"Bacon" => ["Yes"]} }
      it 'returns a string' do
        expect(subject.headers[:bacon]).to eq('Yes')
      end

      it 'converts keys to symbols' do
        expect(subject.headers.keys).to include(:bacon)
      end
    end
  end
end
