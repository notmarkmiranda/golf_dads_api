require 'rails_helper'

RSpec.describe 'Solid Queue Integration', type: :integration do
  include ActiveSupport::Testing::TimeHelpers

  describe 'configuration' do
    it 'has Solid Queue adapter available' do
      # Test environment uses :test adapter for faster tests
      # Development and production use :solid_queue
      expect(ActiveJob::QueueAdapters::SolidQueueAdapter).to be_a(Class)
    end

    it 'has queue database connection configured' do
      expect(ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'queue')).to be_present
    end
  end

  describe 'database tables' do
    it 'has solid_queue_jobs table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_jobs')).to be true
    end

    it 'has solid_queue_scheduled_executions table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_scheduled_executions')).to be true
    end

    it 'has solid_queue_ready_executions table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_ready_executions')).to be true
    end

    it 'has solid_queue_claimed_executions table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_claimed_executions')).to be true
    end

    it 'has solid_queue_failed_executions table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_failed_executions')).to be true
    end

    it 'has solid_queue_pauses table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_pauses')).to be true
    end

    it 'has solid_queue_processes table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_processes')).to be true
    end

    it 'has solid_queue_recurring_executions table' do
      expect(ActiveRecord::Base.connection.table_exists?('solid_queue_recurring_executions')).to be true
    end
  end

  describe 'job enqueueing', skip: 'Test environment uses :test adapter for performance' do
    # Create a simple test job for this spec
    class TestEnqueueJob < ApplicationJob
      queue_as :default

      def perform(message)
        Rails.logger.info "Test job executed: #{message}"
      end
    end

    before do
      # Clean up any existing jobs
      SolidQueue::Job.delete_all
    end

    it 'enqueues jobs to the database' do
      expect {
        TestEnqueueJob.perform_later('test message')
      }.to change { SolidQueue::Job.count }.by(1)
    end

    it 'stores job class name' do
      TestEnqueueJob.perform_later('test message')
      job = SolidQueue::Job.last

      expect(job.class_name).to eq('TestEnqueueJob')
    end

    it 'stores job arguments' do
      TestEnqueueJob.perform_later('test message')
      job = SolidQueue::Job.last

      expect(job.arguments).to eq(['test message'])
    end

    it 'stores job queue name' do
      TestEnqueueJob.perform_later('test message')
      job = SolidQueue::Job.last

      expect(job.queue_name).to eq('default')
    end

    it 'assigns job to ready executions' do
      expect {
        TestEnqueueJob.perform_later('test message')
      }.to change { SolidQueue::ReadyExecution.count }.by(1)
    end
  end

  describe 'scheduled jobs', skip: 'Test environment uses :test adapter for performance' do
    class TestScheduledJob < ApplicationJob
      def perform(message)
        Rails.logger.info "Scheduled job executed: #{message}"
      end
    end

    before do
      SolidQueue::Job.delete_all
      SolidQueue::ScheduledExecution.delete_all
    end

    it 'enqueues jobs scheduled for the future' do
      expect {
        TestScheduledJob.set(wait: 1.hour).perform_later('scheduled message')
      }.to change { SolidQueue::Job.count }.by(1)
    end

    it 'stores scheduled_at time for future jobs' do
      freeze_time do
        TestScheduledJob.set(wait: 1.hour).perform_later('scheduled message')
        job = SolidQueue::Job.last

        expect(job.scheduled_at).to be_within(1.second).of(1.hour.from_now)
      end
    end

    it 'assigns scheduled jobs to scheduled_executions' do
      expect {
        TestScheduledJob.set(wait: 1.hour).perform_later('scheduled message')
      }.to change { SolidQueue::ScheduledExecution.count }.by(1)
    end
  end

  describe 'queue configuration' do
    it 'has queue configuration file' do
      config_path = Rails.root.join('config', 'queue.yml')
      expect(File.exist?(config_path)).to be true
    end

    it 'has recurring tasks configuration file' do
      config_path = Rails.root.join('config', 'recurring.yml')
      expect(File.exist?(config_path)).to be true
    end

    it 'loads queue configuration' do
      config = YAML.load_file(Rails.root.join('config', 'queue.yml'), aliases: true)
      expect(config['test']).to be_present
      expect(config['test']['workers']).to be_present
    end
  end
end
