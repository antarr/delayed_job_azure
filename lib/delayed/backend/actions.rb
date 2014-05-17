module Delayed
  module Backend
    module Azure
      module Actions
        def field(name, options = {})
          #type   = options[:type]    || String
          default = options[:default] || nil
          define_method name do
            @attributes ||= {}
            @attributes[name.to_sym] || default
          end
          define_method "#{name}=" do |value|
            @attributes ||= {}
            @attributes[name.to_sym] = value
          end
        end

        def before_fork
        end

        def after_fork
        end

        def db_time_now
          Time.now.utc
        end

        #def self.queue_name
        #  Delayed::Worker.queue_name
        #end

        def find_available(worker_name, limit = 5, max_run_time = Worker.max_run_time)
          Delayed::Worker.available_priorities.each do |priority|
            unless queues.include? queue_name
              azure.create_queue queue_name
              queues << queue_name
            end

            message = azure.list_messages queue_name(priority), 0
            return [Delayed::Backend::Azure::Job.new(message)] if message
          end
          []
        end

        def delete_all
          deleted = 0
          Delayed::Worker.available_priorities.each do |priority|
            loop do
              msgs = azure.list_messages queue_name(priority), 0, 
                number_of_messages: 1000

              break if msgs.blank?
              msgs.each do |msg|
                azure.delete_message queue_name(priority), msg.id, msg.pop_receipt
                deleted += 1
              end
            end
          end
        end

        # No need to check locks
        def clear_locks!(*args)
          true
        end

        private

        def azure
          ::Delayed::Worker.azure
        end

        def queues
          ::Delayed::Worker.queues
        end

        def queue_name(priority)
          "#{Delayed::Worker.queue_name}_#{priority || 0}"
        end
      end
    end
  end
end