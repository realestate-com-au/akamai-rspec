require 'spec_helper'
require 'rspec/expectations'

describe 'be_permanently_redirected_to' do
  before(:each) do
    stub_redirect(301)
  end

  describe 'chaining' do
    before(:each) do
      stub_status('/redirected', 200)
    end
    it 'should follow redirects' do
      expect(DOMAIN + '/redirect').to be_permanently_redirected_to(DOMAIN + '/redirected').then be_successful
    end
  end

  it 'should be successful on 301 to new' do
    expect(DOMAIN + '/redirect').to be_permanently_redirected_to(DOMAIN + '/redirected')
  end

  it 'should fail on 301 to wrong location' do
    expect { expect(DOMAIN + '/redirect').to be_permanently_redirected_to(DOMAIN + '/wrong') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 300 to correct location' do
    stub_redirect(300)
    expect { expect(DOMAIN + '/redirect').to be_permanently_redirected_to(DOMAIN + '/redirected') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 300 to wrong location' do
    stub_redirect(300)
    expect { expect(DOMAIN + '/redirect').to be_permanently_redirected_to(DOMAIN + '/wrong') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 200' do
    stub_request(:any, DOMAIN + '/redirect').to_return(body: 'abc')
    expect { expect(DOMAIN + '/redirect').to be_permanently_redirected_to(DOMAIN + '/redirected') }
      .to raise_error(RuntimeError)
  end
end

describe 'be_temporarily_redirected_to' do
  before(:each) do
    stub_redirect(302)
  end

  it 'should be successful on 302 to new' do
    expect(DOMAIN + '/redirect').to be_temporarily_redirected_to(DOMAIN + '/redirected')
  end

  it 'should fail on 302 to wrong location' do
    expect { expect(DOMAIN + '/redirect').to be_temporarily_redirected_to(DOMAIN + '/wrong') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 300 to correct location' do
    stub_redirect(300)
    expect { expect(DOMAIN + '/redirect').to be_temporarily_redirected_to(DOMAIN + '/redirected') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 300 to wrong location' do
    stub_redirect(300)
    expect { expect(DOMAIN + '/redirect').to be_temporarily_redirected_to(DOMAIN + '/wrong') }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 200' do
    stub_request(:any, DOMAIN + '/redirect').to_return(body: 'abc')
    expect { expect(DOMAIN + '/redirect').to be_temporarily_redirected_to(DOMAIN + '/redirected') }
      .to raise_error(RuntimeError)
  end
end

describe 'redirect_to_add_trailing_slash' do
  before(:each) do
    stub_redirect(302, '/redirect/')
    stub_request(:any, DOMAIN + '/wrong').to_return(body: 'abc',
                                                    headers: { 'Location' => DOMAIN + '/blerg/' },
                                                    status: [302, 'message'])
  end

  it 'should be successful on 302 to new' do
    expect(DOMAIN + '/redirect').to redirect_to_add_trailing_slash(with: 302)
  end

  it 'should fail on 302 to wrong location' do
    expect { expect(DOMAIN + '/wrong').to redirect_to_add_trailing_slash(with: 302) }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 302 without trailing slash' do
    stub_redirect(302, '/redirected')
    expect { expect(DOMAIN + '/redirect').to redirect_to_add_trailing_slash(with: 302) }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 300 to correct location' do
    stub_redirect(300)
    expect { expect(DOMAIN + '/redirect').to redirect_to_add_trailing_slash(with: 302) }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 300 to wrong location' do
    stub_redirect(300)
    expect { expect(DOMAIN + '/redirect').to redirect_to_add_trailing_slash(with: 302) }
      .to raise_error(RuntimeError)
  end

  it 'should fail on 200' do
    stub_request(:any, DOMAIN + '/redirect').to_return(body: 'abc')
    expect { expect(DOMAIN + '/redirect').to redirect_to_add_trailing_slash(with: 302) }
      .to raise_error(RuntimeError)
  end
end
