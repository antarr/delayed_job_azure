
module Delayed
  module Backend
    module Azure
      class Job
        include ::DelayedJobAzure::Document
        include Delayed::Backend::Base
        extend  Delayed::Backend::Azure::Actions

        field :priority,    :type => Integer, :default => 0
        field :attempts,    :type => Integer, :default => 0
        field :handler,     :type => String
        field :run_at,      :type => Time
        field :locked_at,   :type => Time
        field :locked_by,   :type => String
        field :failed_at,   :type => Time
        field :last_error,  :type => String
        field :queue,       :type => String

        def initialize(data = {})
          @msg = nil
          if data.is_a?(::Azure::Queue::Message)
            @msg = data
            data = JSON.load(data.message_text)
          end

          data.symbolize_keys!
          payload_obj = data.delete(:payload_object) || data.delete(:handler)

          @queue_name = data[:queue_name] || Delayed::Worker.queue_name
          @delay      = data[:delay]      || Delayed::Worker.delay
          @timeout    = data[:timeout]    || Delayed::Worker.timeout
          @expires_in = data[:expires_in] || Delayed::Worker.expires_in
          @attributes = data
          self.payload_object = payload_obj
        end

        def payload_object
          @payload_object ||= YAML.load(self.handler)
        rescue TypeError, LoadError, NameError, ArgumentError => e
          raise DeserializationError,
            "Job failed to load: #{e.message}. Handler: #{handler.inspect}"
        end

        def payload_object=(object)
          if object.is_a? String
            @payload_object = YAML.load(object)
            self.handler = object
          else
            @payload_object = object
            self.handler = object.to_yaml
          end
        end

        def save
          if @attributes[:handler].blank?
            raise "Handler missing!"
          end
          payload = JSON.dump(@attributes)

          destroy if @msg

          unless queues.include? queue_name
            azure.create_queue queue_name
            queues << queue_name
          end

          azure.create_message queue_name, payload,
            timeout:            @timeout,
            visibility_timeout: @delay,
            message_ttl:        @expires_in
          true
        end

        def save!
          save
        end

        def destroy
          if id and pop_receipt
            aure.delete_message(queue_name, id, pop_receipt)
          end
        end

        def fail!
          destroy
          # v2: move to separate queue
        end

        def update_attributes(attributes)
          attributes.symbolize_keys!
          @attributes.merge attributes
          save
        end

        # No need to check locks
        def lock_exclusively!(*args)
          true
        end

        # No need to check locks
        def unlock(*args)
          true
        end

        def reload(*args)
          # reset
          super
        end

        def id
          @msg.id if @msg
        end

        def pop_receipt
          @msg.pop_receipt if @msg
        end

        private

        def queue_name
          "#{@queue_name}_#{@attributes[:priority] || 0}"
        end

        def azure
          ::Delayed::Worker.azure
        end

        def queues
          ::Delayed::Worker.queues
        end
      end
    end
  end
end