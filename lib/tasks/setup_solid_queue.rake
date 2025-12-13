namespace :solid_queue do
  desc "Setup Solid Queue tables manually"
  task setup_tables: :environment do
    conn = ActiveRecord::Base.connection

    puts "Creating solid_queue_jobs..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_jobs (
        id bigserial PRIMARY KEY,
        queue_name text NOT NULL,
        class_name text NOT NULL,
        arguments text,
        priority integer DEFAULT 0 NOT NULL,
        active_job_id text,
        scheduled_at timestamp(6),
        finished_at timestamp(6),
        concurrency_key text,
        created_at timestamp(6) NOT NULL,
        updated_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_processes..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_processes (
        id bigserial PRIMARY KEY,
        kind text NOT NULL,
        last_heartbeat_at timestamp(6) NOT NULL,
        supervisor_id bigint,
        pid integer NOT NULL,
        hostname text NOT NULL,
        metadata text,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_ready_executions..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_ready_executions (
        id bigserial PRIMARY KEY,
        job_id bigint NOT NULL,
        queue_name text NOT NULL,
        priority integer DEFAULT 0 NOT NULL,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_scheduled_executions..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_scheduled_executions (
        id bigserial PRIMARY KEY,
        job_id bigint NOT NULL,
        queue_name text NOT NULL,
        priority integer DEFAULT 0 NOT NULL,
        scheduled_at timestamp(6) NOT NULL,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_claimed_executions..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_claimed_executions (
        id bigserial PRIMARY KEY,
        job_id bigint NOT NULL,
        process_id bigint,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_failed_executions..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_failed_executions (
        id bigserial PRIMARY KEY,
        job_id bigint NOT NULL,
        error text,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_blocked_executions..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_blocked_executions (
        id bigserial PRIMARY KEY,
        job_id bigint NOT NULL,
        queue_name text NOT NULL,
        priority integer DEFAULT 0 NOT NULL,
        concurrency_key text NOT NULL,
        expires_at timestamp(6) NOT NULL,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_recurring_executions..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_recurring_executions (
        id bigserial PRIMARY KEY,
        job_id bigint NOT NULL,
        task_key text NOT NULL,
        run_at timestamp(6) NOT NULL,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_pauses..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_pauses (
        id bigserial PRIMARY KEY,
        queue_name text NOT NULL,
        created_at timestamp(6) NOT NULL
      )
    SQL

    puts "Creating solid_queue_semaphores..."
    conn.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS solid_queue_semaphores (
        id bigserial PRIMARY KEY,
        key text NOT NULL,
        value integer DEFAULT 1 NOT NULL,
        expires_at timestamp(6) NOT NULL,
        created_at timestamp(6) NOT NULL,
        updated_at timestamp(6) NOT NULL
      )
    SQL

    puts "✓ All Solid Queue tables created successfully!"
  end
end
