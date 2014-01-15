require_relative '../test_helper'
require 'omniauth/github_authorization'

describe GithubAuthorization do
  let(:teams) {[]}
  let(:config) { Rails.application.config.pusher.github }
  let(:authorization) { GithubAuthorization.new('test.user', '123') }

  def stub_github_api(url, response = {}, status = 200)
    url = 'https://api.github.com/' + url
    stub_request(:get, url).with(
      headers: { 'Authorization' => 'token 123' }
    ).to_return(
      status: status,
      body: JSON.dump(response),
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  before do
    stub_github_api("orgs/#{config.organization}/teams", teams)

    teams.each do |team|
      stub_github_api("teams/#{team[:id]}/members/test.user", {}, team[:member] ? 204 : 404)
    end
  end

  describe 'with no teams' do
    it 'keeps the user a viewer' do
      authorization.role_id.must_equal(Role::VIEWER.id)
    end
  end

  describe 'with an admin team' do
    let(:teams) {[
      { id: 1, slug: config.admin_team, member: member? }
    ]}

    describe 'as a team member' do
      let(:member?) { true }

      it 'updates the user to admin' do
        authorization.role_id.must_equal(Role::ADMIN.id)
      end
    end

    describe 'not a team member' do
      let(:member?) { false }

      it 'does not update the user to admin' do
        authorization.role_id.must_equal(Role::VIEWER.id)
      end
    end
  end

  describe 'with a deploy team' do
    let(:teams) {[
      { id: 2, slug: config.deploy_team, member: member? }
    ]}

    describe 'as a team member' do
      let(:member?) { true }

      it 'updates the user to admin' do
        authorization.role_id.must_equal(Role::DEPLOYER.id)
      end
    end

    describe 'not a team member' do
      let(:member?) { false }
      it 'does not update the user to admin' do
        authorization.role_id.must_equal(Role::VIEWER.id)
      end
    end
  end

  describe 'with both teams' do
    let(:teams) {[
      { id: 1, slug: config.admin_team, member: true },
      { id: 2, slug: config.deploy_team, member: true }
    ]}

    it 'updates the user to admin' do
      authorization.role_id.must_equal(Role::ADMIN.id)
    end
  end
end
