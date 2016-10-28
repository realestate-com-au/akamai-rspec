require 'spec_helper'

describe 'be_cacheable' do
  before(:each) do
    stub_headers('/cacheable', 'X-Cache' => 'TCP_HIT')
    stub_headers('/not_cacheable', {})
  end

  it 'should succeed when cacheable' do
    expect(DOMAIN + '/cacheable').to be_cacheable
  end

  it 'should fail when not cacheable' do
    expect { expect(DOMAIN + '/not_cacheable').to be_cacheable }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end

describe 'have_no_cache_set' do
  before(:each) do
    stub_headers('/cacheable', 'X-Cache' => 'TCP_HIT')
    stub_headers('/not_cacheable', 'Cache-control' => 'no-cache')
  end

  it 'should succeed when not cacheable' do
    expect(DOMAIN + '/not_cacheable').to have_no_cache_set
  end

  it 'should fail when cacheable' do
    expect { expect(DOMAIN + '/cacheable').to have_no_cache_set }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end

describe 'not_be_cached' do
  before(:each) do
    stub_headers('/not_cacheable', 'X-Cache' => 'TCP_MISS')
    stub_headers('/cacheable', 'X-Cache' => 'TCP_HIT')
  end

  it 'should succeed when not cacheable' do
    expect(DOMAIN + '/not_cacheable').not_to be_cached
  end

  it 'should fail when cacheable but missed' do
    expect { expect(DOMAIN + '/cacheable').not_to be_cached }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end

end

describe 'be_tier_distributed' do
  before(:each) do
    cacheable_uri = Addressable::Template.new DOMAIN + '/cacheable?{random}'
    stub_request(:any, cacheable_uri).to_return(
      body: 'abc', headers: { 'X_Cache_Remote' => 'TCP_MISS' })
    not_cacheable_uri = Addressable::Template.new DOMAIN + '/not_cacheable?{random}'
    stub_request(:any, not_cacheable_uri).to_return(
      body: 'abc', headers: { 'Cache-control' => 'no-cache' })
  end

  it 'should succeed when it is remote cached' do
    expect(DOMAIN + '/cacheable').to be_tier_distributed
  end

  it 'should fail when not remotely cached' do
    expect { expect(DOMAIN + '/not_cacheable').to be_tier_distributed }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end
