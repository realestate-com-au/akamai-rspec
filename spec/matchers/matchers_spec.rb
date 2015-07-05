describe 'have_cp_code_set' do
  before(:each) do
    stub_headers('/correct', 'x-cache-key' => 'cp-code')
    stub_headers('/no-cp', {})
  end

  it 'should succeed when cp code set' do
    expect(DOMAIN + '/correct').to have_cp_code('cp-code')
  end

  it 'should fail when cp code is wrong' do
    expect { expect(DOMAIN + '/correct').to have_cp_code('wrong') }.to raise_error(RuntimeError)
  end

  it 'should fail x-cache-key header is not set' do
    expect { expect(DOMAIN + '/no-cp').to have_cp_code('wrong') }.to raise_error(RuntimeError)
  end
end

describe 'be_served_from_origin' do
  before(:each) do
    x_cache = { 'x-cache-key' => 'origin' }
    stub_headers('/correct', x_cache)
    stub_request(:any, DOMAIN + '/redirect').to_return(
      body: 'abc', headers: x_cache,
      status: [300, 'message'])
  end

  it 'should succeed with 200 and correct origin' do
    expect(DOMAIN + '/correct').to be_served_from_origin('origin')
  end

  it 'should fail on 300 and correct origin' do
    expect { expect(DOMAIN + '/redirect').to be_served_from_origin('origin') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 200 and incorrect origin' do
    expect { expect(DOMAIN + '/correct').to be_served_from_origin('incorrect') }
      .to raise_error(RuntimeError)
  end
end
