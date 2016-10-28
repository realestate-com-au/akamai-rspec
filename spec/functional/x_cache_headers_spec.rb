require 'spec_helper'

describe 'have_cp_code_set' do
  before(:each) do
    stub_headers('/correct', 'x-cache-key' => 'cp-code')
    stub_headers('/correct-true-cache-key', 'x-true-cache-key' => 'cp-code')
    stub_headers('/no-cp', {})
  end

  it 'should succeed when cp code set in x-cache-key' do
    expect(DOMAIN + '/correct').to have_cp_code('cp-code')
  end

  it 'should succeed when cp code set in x-true-cache-key' do
    expect(DOMAIN + '/correct-true-cache-key').to have_cp_code('cp-code')
  end

  it 'should fail when cp code is wrong' do
    expect { expect(DOMAIN + '/correct').to have_cp_code('wrong') }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it 'should fail when both cache-key headers are not set' do
    expect { expect(DOMAIN + '/no-cp').to have_cp_code('wrong') }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end

describe 'be_served_from_origin' do
  before(:each) do
    x_cache = { 'x-cache-key' => 'A/B/1234/123456/000/originsite.example.com/' }
    x_true_cache = { 'x-true-cache-key' => 'A/B/1234/123456/000/originsite.example.com/' }
    stub_headers('/correct', x_cache)
    stub_headers('/correct-true', x_true_cache)
    stub_request(:any, DOMAIN + '/redirect').to_return(
      body: 'abc', headers: x_cache,
      status: [300, 'message'])
  end

  it 'should succeed with 200 and correct origin in x-cache-key' do
    expect(DOMAIN + '/correct').to be_served_from_origin('originsite.example.com')
  end

  it 'should succeed with 200 and correct origin in x-true-cache-key' do
    expect(DOMAIN + '/correct-true').to be_served_from_origin('originsite.example.com')
  end

  it 'should pass on 300 and correct origin' do
    expect(DOMAIN + '/redirect').to be_served_from_origin('originsite.example.com')
  end

  it 'should fail on 200 and incorrect origin' do
    expect { expect(DOMAIN + '/correct').to be_served_from_origin('someothersite.example.com') }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

  it 'should fail on 200 and origin that only partially matches' do
    expect { expect(DOMAIN + '/correct').to be_served_from_origin('site.example.com') }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end
