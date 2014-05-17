This is [Azure Queues](http://azure.microsoft.com/en-us/services/storage/) backend for [delayed_job](http://github.com/collectiveidea/delayed_job)

# Getting Started

## Get credentials


To start using delayed_job_azure, will need to have your storage account setup as mentioned [here](http://azure.microsoft.com/en-us/documentation/articles/storage-ruby-how-to-use-queue-storage/#CreateAccount).

Once your account is setup, you will need to configure your access using one of the methods mentioned on https://github.com/Azure/azure-sdk-for-ruby/.

## Installation

Add the gems to your `Gemfile:`

```ruby
gem 'azure'
gem 'delayed_job'
gem 'delayed_job_azure'
```

Optionally: Add an initializer (`config/initializers/delayed_job.rb`):

```ruby
Delayed::Worker.configure do |config|
  # optional params:
  config.available_priorities = [-1,0,1,2] # Default is [0]. Please note, adding new priorities will slow down picking the next job from queue.  Also note that these priorities must include all priorities of your Delayed Jobs.
  config.queue_name = 'default' # Specify an alternative queue name
  config.delay = 0  # Time to wait before message will be available on the queue
  config.timeout = 5.minutes # The time in seconds to wait after message is taken off the queue, before it is put back on. Delete before :timeout to ensure it does not go back on the queue.
  config.expires_in = 7.days # After this time, message will be automatically removed from the queue.
end
```

## Usage

That's it. Use [delayed_job as normal](http://github.com/collectiveidea/delayed_job).

Example:

```ruby
class User
  def background_stuff
    puts "I run in the background"
  end
end
```

Then in one of your controllers:

```ruby
user = User.new
user.delay.background_stuff
```

## Start worker process

    rake jobs:work

That will start pulling jobs off the queue and processing them.

# Documentation

You can find more documentation here:

* http://azure.microsoft.com/en-us/develop/ruby/