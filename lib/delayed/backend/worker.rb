require_relative 'azure_config'

module Delayed
  class Worker
    class << self
      attr_accessor :config, :queue_name, :delay, :timeout, 
                    :expires_in, :available_priorities

      def configure
        yield(config)
        self.queue_name = config.queue_name || 'default'
        self.delay = config.delay || 0
        self.timeout = config.timeout || 5.minutes
        self.expires_in = config.expires_in || 7.days

        priorities = config.available_priorities || [0]
        if priorities.include?(0) && priorities.all? { |p| p.is_a?(Integer) }
          self.available_priorities = priorities.sort
        else
          raise ArgumentError, "available_priorities option has wrong format. Please provide array of Integer values, includes zero. Default is [0]."
        end
      end

      def config
        @config ||= AzureConfig.new
      end

      def azure
        @azure ||= Azure::QueueService.new
      end

      def queues
        unless @queues
          @queues = Delayed::Worker.azure.list_queues
          @queues.map! { |q| q.name } 
        end
        @queues
      end
    end
  end
end

# initialize with defaults
Delayed::Worker.configure {}