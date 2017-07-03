require 'rails_helper'

module MnoEnterprise
  describe Jpi::V1::AppCommentsController, type: :controller do
    include MnoEnterprise::TestingSupport::JpiV1TestHelper
    include MnoEnterprise::TestingSupport::ReviewsSharedHelpers

    render_views
    routes { MnoEnterprise::Engine.routes }
    before { request.env['HTTP_ACCEPT'] = 'application/json' }

    #===============================================
    # Assignments
    #===============================================
    let(:user) { build(:user) }
    let(:organization) { build(:organization) }
    let(:orga_relation) { build(:orga_relation, user: user, organization: organization) }
    let!(:current_user_stub) { stub_api_v2(:get, "/users/#{user.id}", user, %i(deletion_requests organizations orga_relations dashboards)) }

    before { sign_in user }

    let(:app) { build(:app) }
    let(:comment1) { build(:comment, parent_id: 'fid') }
    let(:comment2) { build(:comment, parent_id: 'fid') }

    before do
      stub_api_v2(:get, "/apps/#{app.id}", app)
    end

    describe 'GET #index' do
      before do
        stub_api_v2(:get, '/comments', [comment1, comment2], [], {filter: {parent_id: 'fid', reviewer_type: 'OrgaRelation', reviewable_type: 'App', status: 'approved', reviewable_id: app.id}})
      end

      subject { get :index, id: app.id, parent_id: 'fid' }

      it_behaves_like 'jpi v1 protected action'

      it_behaves_like 'a paginated action'

      it 'renders the list of reviews' do
        subject
        app_comments = JSON.parse(response.body)['app_comments']
        expect(app_comments[0]).to eq(hash_for_comment(comment1))
        expect(app_comments[1]).to eq(hash_for_comment(comment2))
      end
    end

    describe 'POST #create', focus: true do
      let(:params) { {organization_id: organization.id, description: 'A Review', foo: 'bar', feedback_id: 'fid'} }

      before do
        stub_api_v2(:get, '/orga_relations', [orga_relation], [], {filter: {organization_id: organization.id, user_id: user.id}, page: {number: 1, size: 1}})
        stub_api_v2(:post, '/comments', comment1)
      end

      subject { post :create, id: app.id, app_comment: params }

      it_behaves_like 'jpi v1 protected action'

      it 'renders the new review' do
        expect(JSON.parse(subject.body)['app_comment']).to eq(hash_for_comment(comment1))
      end
    end
  end
end
