class Project < ActiveRecord::Base

  include AASM

  STATUS_MAP = {
      empty:                {id: -1, title: 'Empty'},
      partial_configured:   {id: 1, title: 'Partially Configured'},
      configured:           {id: 2, title: 'Configured'},
      setup_progress:       {id: 3, title: 'Setting up...'},
      ready_start:          {id: 4, title: 'Ready'},
      start_progress:       {id: 9, title: 'Starting...'},
      started:              {id: 5, title: 'Running'},
      stop_progress:        {id: 6, title: 'Stopping...'},
      abort_progress:       {id: 7, title: 'Aborting...'},
      term_progress:        {id: 8, title: 'Terminating...'},
      inactive:             {id: -2, title: 'Inactive'}
  }

  has_many :clusters, dependent: :destroy
  has_many :test_plans, dependent: :destroy
  has_many :load_tests, dependent: :destroy
  has_many :target_hosts
  delegate :data_centers, :amazon_clouds, to: :clusters
  has_many :project_result_downloads

  has_one  :most_recent_finished_load_test, -> { unscope(:where).where.not(stopped_at: nil).order('stopped_at DESC').limit(1) }, class_name: 'LoadTest'

  validates :title, presence: true
  validates :title, uniqueness: true
  validates :project_key, presence: true, uniqueness: true, format: /\A[a-zA-Z][a-zA-Z0-9\-_]*\z/

  before_validation :set_project_key, if: ->(r) { r.project_key.blank? }

  def self.pagination(current_page, items_per_page)
    self.paginate(page: current_page, per_page: items_per_page).order('updated_at DESC')
  end

  def status_title
    STATUS_MAP[aasm.current_state][:title]
  end

  def set_state_reason(reason)
    self.state_reason = reason
  end

  def clear_state_reason
    self.state_reason = nil
  end

  aasm do
    state :empty, initial: true
    state :partial_configured
    state :configured
    state :setup_progress
    state :ready_start
    state :start_progress
    state :started
    state :stop_progress
    state :abort_progress
    state :term_progress
    state :inactive

    event :test_plan_upload do
      transitions from: :empty,               to: :partial_configured
    end

    event :cluster_configuration do
      transitions from: :empty,               to: :partial_configured
      transitions from: :partial_configured,  to: :partial_configured
    end

    event :config_completed do
      transitions from: :partial_configured,  to: :configured
    end

    event :setup, :before => :clear_state_reason do
      transitions from: [:configured, :ready_start],  to: :setup_progress
    end

    event :setup_done do
      transitions from: :setup_progress,      to: :ready_start
    end

    event :setup_fail do
      transitions from: :setup_progress,      to: :configured,    after: ->(*args) { set_state_reason(args[0]) }
      transitions from: :configured,          to: :configured
    end

    event :start, :before => :clear_state_reason do
      transitions from: :ready_start,         to: :start_progress
    end

    event :start_done do
      transitions from: :start_progress,      to: :started
    end

    event :start_fail do
      transitions from: :start_progress,      to: :ready_start,    after: ->(*args) { set_state_reason(args[0]) }
      transitions from: :ready_start,          to: :ready_start
    end

    event :stop, :before => :clear_state_reason do
      transitions from: :started,             to: :stop_progress
    end

    event :stop_done do
      transitions from: :stop_progress,      to: :ready_start
    end

    event :stop_fail do
      transitions from: :stop_progress,      to: :started,         after: ->(*args) { set_state_reason(args[0]) }
      transitions from: :started,            to: :started
    end

    event :abort, :before => :clear_state_reason do
      transitions from: :started,             to: :abort_progress
    end

    event :abort_done do
      transitions from: :abort_progress,      to: :ready_start
    end

    event :abort_fail do
      transitions from: :abort_progress,      to: :started,        after: ->(*args) { set_state_reason(args[0]) }
      transitions from: :started,             to: :started
    end

    event :terminate, :before => :clear_state_reason do
      transitions from: [:setup_progress, :ready_start, :start_progress, :started, :stop_progress, :abort_progress], to: :term_progress
    end

    event :terminate_done do
      transitions from: :term_progress,       to: :configured
    end

    event :terminate_fail do
      transitions from: :term_progress,       to: :ready_start,    after: ->(*args) { set_state_reason(args[0]) }
      transitions from: :ready_start,         to: :ready_start
    end

    event :inactivate do
      transitions from: [:empty, :partial_configured, :configured], to: :inactive
    end
  end

  def anything_in_progress?
    setup_progress? || start_progress? || stop_progress? || abort_progress? || term_progress? || started?
  end

  def reports_dir_path
    File.join(Rails.configuration.project_setup_path, project_key, 'reports')
  end

  def generated_reports(&block)
    files = [];
    Dir["#{reports_dir_path}/*.docx", "#{reports_dir_path}/*.zip"].each do |rpt_file_path|
      mtime = File.mtime(rpt_file_path)
      files << {f: rpt_file_path, m: mtime}
    end

    files.sort! {|a, b| b[:m] <=> a[:m]}

    if block_given?
      files.each do |f|
        yield f[:f]
      end
    else
      files.map { |f| f[:f]}
    end
  end

  private

  def set_project_key
    self.project_key = self.title.gsub(/[^a-zA-Z0-9\-_]/, '').underscore
  end

end
