require 'spec_helper'
require 'hailstorm/cli/view_renderer'
require 'hailstorm/model/project'
require 'hailstorm/model/jmeter_plan'
require 'hailstorm/model/amazon_cloud'
require 'hailstorm/model/nmon'

describe Hailstorm::Cli::ViewRenderer do
  before(:each) do
    @app = Hailstorm::Cli::ViewRenderer.new(mock(Hailstorm::Model::Project))
  end

  context '#render_status' do
    before(:each) do
      @app.stub!(:view_template).and_return(mock(Hailstorm::Cli::ViewTemplate))
    end
    context 'load generation in progress' do
      it 'should show running agents' do
        @app.view_template.should_receive(:render_running_agents)
        @app.render_status([{}])
      end
    end
    context 'load generation finished' do
      it 'should show no running agents' do
        @app.view_template.should_not_receive(:render_running_agents)
        @app.render_status([], :json)
      end
    end
  end

  context '#render_show' do
    before(:each) do
      @query_map = { jmeter_plans: [], clusters: [], target_hosts: [] }
    end
    it 'should show everything active' do
      @app.view_template.should_receive(:render_jmeter_plans) { |_q, flag| expect(flag).to be_true }
      @app.view_template.should_receive(:render_load_agents) { |_q, flag| expect(flag).to be_true }
      @app.view_template.should_receive(:render_target_hosts) { |_q, flag| expect(flag).to be_true }
      @app.render_show(@query_map, true, :active)
    end
    context 'jmeter' do
      it 'should show active jmeter' do
        @app.view_template.should_receive(:render_jmeter_plans) { |_q, flag| expect(flag).to be_true }
        @app.view_template.should_not_receive(:render_load_agents)
        @app.view_template.should_not_receive(:render_target_hosts)
        @app.render_show(@query_map, true,:jmeter)
      end
      context 'all' do
        it 'should show all jmeter' do
          @app.view_template.should_receive(:render_jmeter_plans) { |_q, flag| expect(flag).to be_false }
          @app.view_template.should_not_receive(:render_load_agents)
          @app.view_template.should_not_receive(:render_target_hosts)
          @app.render_show(@query_map, false, :jmeter)
        end
      end
    end
    context 'cluster' do
      it 'should show active cluster' do
        @app.view_template.should_receive(:render_load_agents) { |_q, flag| expect(flag).to be_true }
        @app.view_template.should_not_receive(:render_jmeter_plans)
        @app.view_template.should_not_receive(:render_target_hosts)
        @app.render_show(@query_map, true, :cluster)
      end
      context 'all' do
        it 'should show all cluster' do
          @app.view_template.should_receive(:render_load_agents) { |_q, flag| expect(flag).to be_false }
          @app.view_template.should_not_receive(:render_jmeter_plans)
          @app.view_template.should_not_receive(:render_target_hosts)
          @app.render_show(@query_map, false, :cluster)
        end
      end
    end
    context 'monitor' do
      it 'should show active monitor' do
        @app.view_template.should_receive(:render_target_hosts) { |_q, flag| expect(flag).to be_true }
        @app.view_template.should_not_receive(:render_jmeter_plans)
        @app.view_template.should_not_receive(:render_load_agents)
        @app.render_show(@query_map, true, :monitor)
      end
      context 'all' do
        it 'should show all monitor' do
          @app.view_template.should_receive(:render_target_hosts) { |_q, flag| expect(flag).to be_false }
          @app.view_template.should_not_receive(:render_jmeter_plans)
          @app.view_template.should_not_receive(:render_load_agents)
          @app.render_show(@query_map, false, :monitor)
        end
      end
    end
    context 'active' do
      it 'should show everything active' do
        @app.view_template.should_receive(:render_jmeter_plans) { |_q, flag| expect(flag).to be_true }
        @app.view_template.should_receive(:render_load_agents) { |_q, flag| expect(flag).to be_true }
        @app.view_template.should_receive(:render_target_hosts) { |_q, flag| expect(flag).to be_true }
        @app.render_show(@query_map, true, :active)
      end
    end
    context 'all' do
      it 'should show everything including inactive' do
        @app.view_template.should_receive(:render_jmeter_plans) { |_q, flag| expect(flag).to be_false }
        @app.view_template.should_receive(:render_load_agents) { |_q, flag| expect(flag).to be_false }
        @app.view_template.should_receive(:render_target_hosts) { |_q, flag| expect(flag).to be_false }
        @app.render_show(@query_map, false, :all)
      end
    end
  end

  context '#render_setup' do
    before(:each) do
      project = Hailstorm::Model::Project.create!(project_code: 'view_template_spec')
      test_plan = Hailstorm::Model::JmeterPlan.create!(active: false, project: project,
                                                       test_plan_name: 'view_template_spec', content_hash: 'A')
      test_plan.update_attribute(:properties, {NumUsers: 100}.to_json)
      test_plan.update_column(:active, true)
      amz = Hailstorm::Model::AmazonCloud.create!(project: project, access_key: 'A', secret_key: 'A')
      Hailstorm::Model::Cluster.create!(project: project, cluster_type: amz.class.name)
      amz.update_column(:active, true)
      monitor = Hailstorm::Model::Nmon.create!(project: project, host_name: 'app.de.mon', role_name: 'server',
                                               executable_pid: 2345)
      monitor.update_column(:active, true)
      @app.stub!(:project).and_return(project)
    end
    it 'should render jmeter plans' do
      @app.view_template.should_receive(:render_jmeter_plans)
      @app.render_setup
    end
    it 'should render defaults' do
      @app.should_receive(:render_default)
      @app.render_setup
    end
  end
end
