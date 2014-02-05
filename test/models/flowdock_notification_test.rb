require 'test_helper'

describe FlowdockNotification do
  let(:project) { stub(name: "Glitter") }
  let(:user) { stub(name: "John Wu", email: "wu@rocks.com") }
  let(:stage) { stub(name: "staging", flowdock_tokens: ["x123yx"], project: project) }
  let(:deploy) { stub(summary: "hello world!", user: user) }
  let(:notification) { FlowdockNotification.new(stage, deploy) }
  let(:endpoint) { "https://api.flowdock.com/v1/messages/team_inbox/x123yx" }

  before do
    FlowdockNotificationRenderer.stubs(:render).returns("foo")
  end

  it "notifies all Flowdock flows configured for the stage" do
    delivery = stub_request(:post, endpoint)
    notification.deliver

    assert_requested delivery
  end

  it "renders a nicely formatted notification" do
    stub_request(:post, endpoint)
    FlowdockNotificationRenderer.stubs(:render).returns("bar")
    notification.deliver

    content = nil
    assert_requested :post, endpoint do |request|
      body = Rack::Utils.parse_query(request.body)
      content = body.fetch("content")
    end

    content.must_equal "bar"
  end
end
