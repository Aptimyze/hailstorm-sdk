require 'hailstorm/behavior'
require 'hailstorm/behavior/loggable'

# Mixin for all monitors, provides implementation for some common tasks
# and defines "abstract" methods for the delegates.
# @author Sayantam Dey
module Hailstorm::Behavior::Moniterable

  include Hailstorm::Behavior::Loggable

  # An "abstract" method definition. Implementation should start resource
  # monitoring on the target host.
  # @abstract
  def start_monitoring
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # An "abstract" method definition. Implementation should stop resource
  # monitoring on the target host.
  # @abstract
  def stop_monitoring
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # An "abstract" method definition. Implementation should calculate and return the
  # average CPU utilization from start_time to end_time. If the implementation uses
  # a log file scheme, the start_time and end_time may be ignored since this method
  # would be invoked right after call to #analyze_log_files.
  # @param [Time] _start_time
  # @param [Time] _end_time
  # @return [Float]
  # @abstract
  def average_cpu_usage(_start_time, _end_time)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # An "abstract" method definition. Implementation should calculate and return the
  # average memory utilization from start_time to end_time. If the implementation uses
  # a log file scheme, the start_time and end_time may be ignored since this method
  # would be invoked right after call to #analyze_log_files.
  # @param [Time] _start_time
  # @param [Time] _end_time
  # @return [Float]
  # @abstract
  def average_memory_usage(_start_time, _end_time)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # An "abstract" method definition. Implementation should calculate and return the
  # average swap utilization from start_time to end_time. If the implementation uses
  # a log file scheme, the start_time and end_time may be ignored since this method
  # would be invoked right after call to #analyze_log_files.
  # @param [Time] _start_time
  # @param [Time] _end_time
  # @return [Float]
  # @abstract
  def average_swap_usage(_start_time, _end_time)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # An "abstract" method definition. Implementation should yield or return an
  # IO instance, which will be read for trend information. If a block is provided,
  # the implementation should close the IO connection gracefully. These methods
  # will always be called after the averages methods are called, so the same
  # execution context will apply.
  # @abstract
  def cpu_usage_trend(&_block)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # (see #cpu_usage_trend)
  def memory_usage_trend(&_block)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # (see #cpu_usage_trend)
  def swap_usage_trend(&_block)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implement this method to parse the CPU usage file and return/yield each sample
  # (total CPU% used). The file format and data would be same as originally captured by
  # the implementation.
  # @param [String] _cpu_usage_file_path path to usage file
  # @abstract
  def each_cpu_usage_sample(_cpu_usage_file_path, &_block)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Same as #each_cpu_usage_sample, but this is for memory usage.
  # @param [String] _memory_usage_file_path path to usage file
  # @abstract
  def each_memory_usage_sample(_memory_usage_file_path, &_block)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Same as #each_cpu_usage_sample, but this is for swap usage.
  # @param [String] _swap_usage_file_path path to usage file
  # @abstract
  def each_swap_usage_sample(_swap_usage_file_path, &_block)
    raise(NotImplementedError, "#{self.class}##{__method__} implementation not found.")
  end

  # Implementation should download the remote log file(s) to local_log_path, if
  # implementations use a log file scheme.
  # @param [String] _local_log_path local directory to place downloaded file(s)
  # @return [Array] of String - local file name(s)
  def download_remote_log(_local_log_path)
    # override and do something appropriate
  end

  # An empty method definition. Implementation should override to perform activities
  # necessary prior to starting the monitoring service. The implementation can
  # make changes to the state of the record, but should not persist the changes.
  def setup
    # override and do something appropriate
  end

  # An empty method definition. Implementation should override to cleanup or do
  # other housekeeping activities at the end of a test cycle/run.
  def cleanup
    # override and do something appropriate
  end

  # If implementation downloads remote log files, it must implement this method
  # to analysze the log_file_paths for subsequent calls to calculate methods
  # for averages for CPU, memory and swap usage.
  # @param [Array] _log_file_paths array of path to local log files
  # @param [Time] _start_time the start time of the test
  # @param [Time] _end_time the end time of the test
  def analyze_log_files(_log_file_paths, _start_time, _end_time)
    # override and do something appropriate
  end

  # Iterates through the monitor_config and returns the host definitions
  # @param [Hailstorm::Support::Configuration::TargetHost] monitor_config instance_eval
  #                                                        to include groups
  # @return [Array] of Hash, with attributes mapped to Hailstorm::Model::TargetHost
  def host_definitions(monitor_config)
    logger.debug { "#{self.class}##{__method__}" }
    host_defs = []
    monitor_config.groups.each do |group|
      group.hosts.each do |host|
        hdef = host.instance_values.symbolize_keys
        hdef[:monitor_type] = monitor_config.monitor_type
        hdef[:role_name] = group.role
        %i[executable_path ssh_identity user_name
           sampling_interval active].each do |sym|

          # take values from monitor_config unless the hdef contains the key
          hdef[sym] = monitor_config.send(sym) unless hdef.key?(sym)
        end
        hdef[:active] = true if hdef[:active].nil?
        host_defs.push(hdef)
      end
    end
    host_defs
  end

end
