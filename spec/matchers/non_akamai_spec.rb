require 'spec_helper'

describe "be_successful" do
  before(:each) do
    stub_status("/success", 200)
    stub_status("/fail", 400)
  end

  it "should pass when it gets a 200" do
    expect(DOMAIN + "/success").to be_successful
  end

  it "should fail when it gets 400" do
    expect{expect(DOMAIN + "/fail").to be_successful}.to raise_error(RuntimeError)
  end
end
