require 'spec_helper'
require 'rspec/expectations'
require 'openssl'

describe 'be_successful' do
  before(:each) do
    stub_status('/success', 200)
    stub_status('/fail', 400)
  end

  it 'should pass when it gets a 200' do
    expect(DOMAIN + '/success').to be_successful
  end

  it 'should fail when it gets 400' do
    expect { expect(DOMAIN + '/fail').to be_successful }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it 'allows overriding the expected range' do
    expect(DOMAIN + '/success').not_to be_successful(response_codes: 201..300)
  end
end

describe 'be_gzipped' do
  before(:each) do
    zip = File.open('spec/fixtures/bar.gz', 'r')
    stub_headers('/gzipped', { 'content-encoding' => 'gzip' }, zip.read)
    stub_headers('/not_gzipped_lies', 'content-encoding' => 'gzip')
    stub_headers('/gzipped_lies', { 'content-encoding' => 'something-else' }, zip.read)
    stub_headers('/not_gzipped', 'content-encoding' => 'stuff')
    zip.close
  end

  it 'should pass when gzipped' do
    expect(DOMAIN + '/gzipped').to be_gzipped
  end

  it 'should fail when not gzipped but header lies' do
    expect { expect(DOMAIN + '/not_gzipped_lies').to be_gzipped }
      .to raise_error(Zlib::GzipFile::Error)
  end

  it 'should fail when gzipped but header lies' do
    expect { expect(DOMAIN + '/gzipped_lies').to be_gzipped }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it 'should fail when not gzipped' do
    expect { expect(DOMAIN + '/not_gzipped').to be_gzipped }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end

describe 'have_cookie' do
  before(:each) do
    stub_headers('/omnom', 'set-cookie' => 'cookie=yummy')
    stub_headers('/no-cookie', {})
  end

  it 'should pass when cookie is set' do
    expect(DOMAIN + '/omnom').to have_cookie('cookie')
  end

  it 'should fail when cookie is not set' do
    expect { expect(DOMAIN + '/omnom').to have_cookie('wrong') }.to raise_error(RuntimeError)
  end

  it 'should fail when there are no cookies' do
    expect { expect(DOMAIN + '/no-cookie').to have_cookie('wrong') }.to raise_error(RuntimeError)
  end
end

describe 'be_verifiably_secure' do
  describe 'verifying a URL with the http protocol' do
    it 'fails' do
      expect("http://#{DOMAIN}").not_to be_verifiably_secure
    end
  end

  describe 'verifying a URL with no protocol' do
    it "attempts to connect via https" do
      stub_request(:any, "https://#{DOMAIN}").to_return(body: 'abc')
      expect(DOMAIN).to be_verifiably_secure
    end
  end

  describe 'verifying a URL with the https protocol' do
    it "succeeds when it verifies correctly" do
      stub_request(:any, "https://#{DOMAIN}").to_return(body: 'abc')
      expect("https://#{DOMAIN}").to be_verifiably_secure
    end
  end
end

describe 'be_forbidden' do
  before(:each) do
    stub_status('/success', 200)
    stub_status('/notfound', 404)
    stub_status('/forbidden', 403)
  end

  it 'should pass when it gets a 403' do
    expect(DOMAIN + '/forbidden').to be_forbidden
  end

  it 'should fail when it gets 404' do
    expect { expect(DOMAIN + '/notfound').to be_forbidden }.to raise_error(RuntimeError)
  end

  it 'should fail when it gets 200' do
    expect { expect(DOMAIN + '/success').to be_forbidden }.to raise_error(RuntimeError)
  end
end
