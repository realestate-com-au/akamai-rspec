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
  it 'should succeed with 200 and correct origin' do
    pending
  end

  it 'should fail on 300 and correct origin' do
    pending
  end

  it 'should fail on 200 and incorrect origin' do
    pending
  end
end
