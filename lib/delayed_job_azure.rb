# encoding: utf-8
require 'azure'
require 'delayed_job'

require_relative 'delayed/serialization/azure'
require_relative 'delayed/backend/actions'
require_relative 'delayed/backend/azure_config'
require_relative 'delayed/backend/worker'
require_relative 'delayed/backend/version'
require_relative 'delayed/backend/azure'

Delayed::Worker.backend = :azure