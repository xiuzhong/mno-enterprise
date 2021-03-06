require 'rails_helper'
require 'mno_enterprise/testing_support/shared_contexts/jpi_v1_admin_controller'

module MnoEnterprise
  describe Jpi::V1::Admin::Impac::WidgetsController, type: :controller do
    include_context MnoEnterprise::Jpi::V1::Admin::BaseResourceController

    let(:user) { build(:user, :admin, :with_organizations) }
    let(:org) { build(:organization, users: [user]) }
    let(:template) { build(:impac_dashboard, dashboard_type: 'template') }
    let(:metadata) { { hist_parameters: { from: '2015-01-01', to: '2015-03-31', period: 'MONTHLY' } } }
    let(:widget) { build(:impac_widget, dashboard: template, settings: metadata, layouts: ['figure', 'highcharts']) }
    let(:kpi) { build(:impac_kpi, widget: widget) }

    let(:hash_for_kpi) do
      {
        "id" => kpi.id,
        "element_watched" => kpi.element_watched,
        "endpoint" => kpi.endpoint
      }
    end
    let(:hash_for_widget) do
      {
        "id" => widget.id,
        "name" => widget.name,
        'metadata' => metadata.deep_stringify_keys,
        "endpoint" => widget.widget_category,
        "width" => widget.width,
        "kpis" => [hash_for_kpi],
        "layouts" => widget.layouts
      }
    end

    describe '#create' do
      let(:widget_params) do
        {
          endpoint: widget.endpoint,
          name: widget.name,
          width: widget.width,
          metadata: metadata,
          layouts: widget.layouts,
          forbidden: 'param'
        }
      end

      context 'with a dashboard' do
        subject { post :create, dashboard_id: dashboard.id, widget: widget_params }

        let(:dashboard) { build(:impac_dashboard) }

        context 'when the dashboard exists' do
          before do
            api_stub_for(
              get: "/dashboards",
              params: {
                filter: { 'id' => dashboard.id, 'owner_id' => user.id, 'owner_type' => 'User' },
                limit: 1
              },
              response: from_api([dashboard])
            )
            api_stub_for(
              post: "dashboards/#{dashboard.id}/widgets",
              response: from_api(widget)
            )
            # Why is Her doing a GET /widgets after doing a POST /widgets?
            api_stub_for(
              get: "dashboards/#{dashboard.id}/widgets",
              response: from_api([widget])
            )
            api_stub_for(
              get: "/widgets/#{widget.id}/kpis",
              response: from_api([kpi])
            )
          end

          it_behaves_like "a jpi v1 admin action"

          it 'returns a widget' do
            subject
            expect(JSON.parse(response.body)).to eq(hash_for_widget)
          end
        end

        context 'when the dashboard does not exist' do
          before do
            api_stub_for(
              get: "/dashboards",
              params: {
                filter: { 'id' => dashboard.id, 'owner_id' => user.id, 'owner_type' => 'User' },
                limit: 1
              },
              response: from_api([])
            )
          end

          it 'returns an error message' do
            subject
            expect(response).to have_http_status(:not_found)
            expect(JSON.parse(response.body)).to eq({ 'errors' => { 'message' => 'Dashboard not found' } })
          end
        end
      end

      context 'with a dashboard template' do
        subject { post :create, dashboard_template_id: template.id, widget: widget_params }

        context 'when the template exists' do
          before do
            api_stub_for(
              get: "/dashboards/#{template.id}",
              params: { filter: { 'dashboard_type' => 'template' } },
              response: from_api(template)
            )
            api_stub_for(
              post: "dashboards/#{template.id}/widgets",
              response: from_api(widget)
            )
            # Why is Her doing a GET /widgets after doing a POST /widgets?
            api_stub_for(
              get: "dashboards/#{template.id}/widgets",
              response: from_api([widget])
            )
            api_stub_for(
              get: "/widgets/#{widget.id}/kpis",
              response: from_api([kpi])
            )
          end

          it_behaves_like "a jpi v1 admin action"

          it 'returns a widget' do
            subject
            expect(JSON.parse(response.body)).to eq(hash_for_widget)
          end
        end

        context 'when the template does not exist' do
          before do
            api_stub_for(
              get: "/dashboards/#{template.id}",
              params: { filter: { 'dashboard_type' => 'template' } },
              code: 404
            )
          end

          it 'returns an error message' do
            subject
            expect(JSON.parse(response.body)).to eq({ 'errors' => { 'message' => 'Dashboard template not found' } })
          end
        end
      end
    end

    describe '#update' do
      let(:widget_params) do
        {
          name: widget.name,
          width: widget.width,
          metadata: metadata,
          forbidden: 'param'
        }
      end

      subject { put :update, id: widget.id, widget: widget_params }

      context 'when the widget exists' do
        before do
          api_stub_for(
            get: "widgets/#{widget.id}",
            response: from_api(widget)
          )
          api_stub_for(
            put: "/widgets/#{widget.id}",
            response: from_api(widget)
          )
          api_stub_for(
            get: "/widgets/#{widget.id}/kpis",
            response: from_api([kpi])
          )
        end

        it_behaves_like "a jpi v1 admin action"

        it 'returns a widget' do
          subject
          expect(JSON.parse(response.body)).to eq(hash_for_widget)
        end
      end

      context 'when the widget does not exist' do
        before do
          api_stub_for(
            get: "widgets/#{widget.id}",
            code: 404
          )
        end

        it 'returns an error message' do
          subject
          expect(JSON.parse(response.body)).to eq({ 'errors' => 'Cannot update widget' })
        end
      end
    end

    describe '#destroy' do
      subject { delete :destroy, id: widget.id }

      context 'when the widget exists' do
        before do
          api_stub_for(
            get: "widgets/#{widget.id}",
            response: from_api(widget)
          )
          api_stub_for(
            delete: "/widgets/#{widget.id}",
            response: from_api(nil)
          )
        end

        it_behaves_like "a jpi v1 admin action"
      end

      context 'when the widget does not exist' do
        before do
          api_stub_for(
            get: "widgets/#{widget.id}",
            code: 404
          )
        end

        it 'returns an error message' do
          subject
          expect(JSON.parse(response.body)).to eq({ 'errors' => 'Cannot delete widget' })
        end
      end
    end
  end
end
