require 'hailstorm/behavior'
require 'hailstorm/model/jmeter_plan'
require 'hailstorm/model/slave_agent'
require 'hailstorm/model/master_agent'
require 'hailstorm/behavior/loggable'

# Defines an interface for an entity that wants to take control of the cluster
# of load agents.
#
# For example, Hailstorm::Model::AmazonCloud includes the Hailstorm::Clusterable
# module and implements the methods in the module.
#
# When adding support for other clusters (like a custom datacenter or Heroku),
# set the Hailstorm::Model::Project#cluster_type to the unqualified class name
# and implement the Hailstorm::Clusterable interface.
#
# @author Sayantam Dey
module Hailstorm::Behavior::Clusterable

  include Hailstorm::Behavior::Loggable

  # Implement this method to start the agent and update load_agent
  # attributes for persistence.
  # @param [Hailstorm::Model::LoadAgent] _load_agent
  # @return [Hash] load agent attributes for persistence
  # @abstract
  def start_agent(_load_agent)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implement this method to stop the load agent and update load_agent
  # attributes for persistence.
  # @param [Hailstorm::Model::LoadAgent] _load_agent
  # @return [Hash] load agent attributes for persistence
  # @abstract
  def stop_agent(_load_agent)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implement this method to return a description of the clusterable instance
  # @return [String]
  # @abstract
  def slug
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implement to return JSON of attributes to display in a report.
  # @return [Hash] attributes
  # @abstract
  def public_properties
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implementation should essentially perform validation, persistence and state
  # management tasks. This method may be called on a new or existing instance,
  # the implementation will have to check and take appropriate actions.
  # @param [Boolean] _force Implementation may redo actions even if already done.
  def setup(_force = false)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implement to get load agent count for each cluster type
  # @param [Hailstorm::Model::JmeterPlan] _jmeter_plan
  # @return [Int] count of required load agents to run the test
  # @abstract
  def required_load_agent_count(_jmeter_plan)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implement this method to perform additional tasks before starting load generation,
  # default method is empty.
  def before_generate_load
    # override and do something appropriate.
  end

  # Implement this method to perform additional tasks after starting load generation,
  # default method is empty.
  def after_generate_load
    # override and do something appropriate.
  end

  # Implement this method to perform additional tasks before stopping load generation.
  def before_stop_load_generation
    # override and do something appropriate.
  end

  # Implement this method to perform additional tasks after stopping load generation.
  # @param [Hash] _options
  def after_stop_load_generation(_options = nil)
    # override and do something appropriate.
  end

  # Implement this method to perform tasks before removing a load agent
  # from the database.
  # @param [Hailstorm::Model::LoadAgent] _load_agent
  def before_destroy_load_agent(_load_agent)
    # override and do something appropriate.
  end

  # Implement this method to perform tasks after removing load agent from the
  # database.
  # @param [Hailstorm::Model::LoadAgent] _load_agent
  def after_destroy_load_agent(_load_agent)
    # override and do something appropriate.
  end

  # Implement this method to return a Hash of options that are processed by
  # Net::SSH. Default is to return an empty Hash.
  # @return [Hash]
  def ssh_options
    {} # override and do something appropriate.
  end

  # Implement this method to perform house keeping activities after
  # all load agents have been destroyed. This method is call right after the
  # call to <tt>destory_all_agents()</tt> method.
  def cleanup
    # override and do something appropriate.
  end

  # Assumes a standard Linux OS where user home is at /home or /root for root. If the clusterable
  # uses a different OS or setting, override this method.
  # @return [String] user home directory
  def user_home
    @user_home ||= self.user_name.to_s.to_sym != :root ? "/home/#{self.user_name}" : '/root'
  end

  # Assumes Jmeter is installed to user_home at jmeter directory. If the clusterable
  # uses a different location, override this method
  # @return [String] full path to jmeter home (up to but not including bin) on load agents
  def jmeter_home
    @jmeter_home ||= "#{user_home}/jmeter"
  end

  # Callback which gets executed when the module is included in a class or module.
  # The Ruby VM calls this automatically.
  # @param [Class] recipient the class/module which included this module
  def self.included(recipient)
    recipient.belongs_to(:project)

    recipient.has_many(:load_agents, as: :clusterable, dependent: :destroy)

    recipient.has_many(:master_agents, as: :clusterable)

    recipient.has_many(:slave_agents, as: :clusterable)

    recipient.has_many(:client_stats, as: :clusterable, dependent: :destroy)

    recipient.after_commit(:disable_agents, on: :update, unless: proc { |r| r.active? })
  end

  # Start JMeter slaves on load agents
  def start_slave_process(redeploy = false)
    logger.debug { "#{self.class}##{__method__}" }
    visit_collection(self.slave_agents.where(active: true)) do |agent|
      agent.upload_scripts(redeploy)
      agent.start_jmeter
    end
  end

  # Start JMeter master on load agents
  def start_master_process(redeploy = false)
    logger.debug { "#{self.class}##{__method__}" }
    visit_collection(self.master_agents.where(active: true)) do |agent|
      agent.upload_scripts(redeploy)
      agent.start_jmeter
    end
  end

  def stop_master_process(wait = false, aborted = false)
    logger.debug { "#{self.class}##{__method__}" }
    visit_collection(self.master_agents.where(active: true)) do |master|
      master.stop_jmeter(wait, aborted)
    end
  end

  def destroy_all_agents
    logger.debug { "#{self.class}##{__method__}" }
    visit_collection(self.load_agents) do |agent|
      before_destroy_load_agent(agent)
      agent.transaction do
        agent.destroy
        after_destroy_load_agent(agent)
      end
    end
  end

  # Checks status of JMeter execution on agents and returns array of MasterAgent
  # instances where JMeter is still running. An empty array means JMeter is not
  # running on any agent.
  # @return [Array] of Hailstorm::Model::MasterAgent
  def check_status
    logger.debug { "#{self.class}##{__method__}" }
    mutex = Mutex.new
    running_agents = []
    visit_collection(self.master_agents.where(active: true)) do |master|
      agent = master.check_status
      mutex.synchronize { running_agents.push(agent) } unless agent.nil?
    end

    running_agents
  end

  protected

  # Launch new instances or bring down instances based on number of instances needed
  # @return [Array<Hailstorm::Model::LoadAgent>]  activated agents
  def provision_agents
    return if self.destroyed?
    logger.debug { "#{self.class}##{__method__}" }
    self.project.jmeter_plans.where(active: true).all.collect { |jmeter_plan| process_jmeter_plan(jmeter_plan) }.flatten
  end

  # Calculates the number of agents to be added based on required and current count. Override this method
  # if a clusterable uses a different strategy. See Hailstorm::Model::DataCenter.
  # @param [ActiveRecord::Relation] query basic relation query that adds common attributes.
  # @param [Fixnum] required_count
  # @yield [ActiveRecord::Relation], [Fixnum] Enumerable for agents that need to be removed, Size of Enumerable
  def agents_to_add(query, required_count, &_block)
    logger.debug { "#{self.class}##{__method__}" }
    active_count = query.count
    activate_count = required_count - active_count
    if block_given?
      activate_count.times do
        yield query, activate_count
      end
    end
    activate_count
  end

  # Calculates the number of agents to be removed based on required and current count. Override this method
  # if a clusterable uses a different strategy. See Hailstorm::Model::DataCenter.
  # @param [ActiveRecord::Relation] query basic relation query that adds common attributes.
  # @param [Fixnum] required_count
  # @yield [ActiveRecord::Relation] Enumerable for agents that need to be removed.
  def agents_to_remove(query, required_count, &_block)
    logger.debug { "#{self.class}##{__method__}" }
    activate_count = agents_to_add(query, required_count)
    return if activate_count >= 0
    query.limit(activate_count.abs).each { |agent| yield agent }
  end

  private

  # Processes each plan to launch new agents, enable them or disable them based on required count
  # @param [Hailstorm::Model::JMeterPlan] jmeter_plan
  #
  # @return [Array<Hailstorm::Model::LoadAgent>] activated agents
  def process_jmeter_plan(jmeter_plan)
    logger.debug { "#{self.class}##{__method__}(#{jmeter_plan})" }
    common_attributes = {
      jmeter_plan_id: jmeter_plan.id,
      active: true
    }

    required_count = required_load_agent_count(jmeter_plan)

    if self.project.master_slave_mode?
      query = self.master_agents
                  .where(jmeter_plan_id: jmeter_plan.id)

      # abort if more than 1 master agent is present
      raise(Hailstorm::MasterSlaveSwitchOnConflict) if query.all.count > 1

      # one master is necessary
      query.first_or_create!.tap { |agent| agent.update_column(:active, true) }

      if required_count > 1
        create_or_enable(common_attributes, required_count, :slave_agents)
      end

    else # not operating in master-slave mode
      # abort if slave agents are present
      slave_agents_count = self.slave_agents
                               .where(jmeter_plan_id: jmeter_plan.id)
                               .all.count
      raise(Hailstorm::MasterSlaveSwitchOffConflict) if slave_agents_count > 0

      begin
        create_or_enable(common_attributes, required_count, :master_agents)
      rescue Exception => e
        logger.debug(e.message)
        logger.debug { "\n".concat(e.backtrace.join("\n")) }
        raise(Hailstorm::AgentCreationFailure)
      end
    end
  end

  # Creates master/slave agents based on the relation
  def create_or_enable(attributes, required_count, relation)
    logger.debug { "#{self.class}##{__method__}(#{[attributes, required_count, relation]})" }
    activated_agents = []
    mutex = Mutex.new

    query = self.send(relation).where(attributes)
    activate_count = agents_to_add(query, required_count) do |q, count|
      # is there an inactive agent? if yes, activate it, or, create new
      agent = q.unscope(where: :active).where(active: false).first_or_initialize { |r| r.active = true }
      if agent.new_record?
        if count > 1
          Hailstorm::Support::Thread.start(agent) do |agent_instance|
            start_agent(agent_instance)
            agent_instance.save!
            mutex.synchronize { activated_agents.push(agent_instance) }
          end
        else
          start_agent(agent)
          agent.save!
          activated_agents.push(agent)
        end
      else
        agent.update_column(:active, true)
      end
    end
    Hailstorm::Support::Thread.join if activate_count > 1 # wait for agents to be created

    agents_to_remove(query, required_count) { |agent| agent.update_column(:active, false) }

    activated_agents
  end

  # disable all associated load_agents
  def disable_agents
    return if self.destroyed?
    logger.debug { "#{self.class}##{__method__}" }
    self.load_agents.each { |agent| agent.update_column(:active, false) }
  end

  def visit_collection(collection, &_block)
    if collection.count == 1
      yield collection.first
    else
      collection.each do |element|
        Hailstorm::Support::Thread.start(element) do |e|
          yield e
        end
      end
      Hailstorm::Support::Thread.join
    end
  end

end
