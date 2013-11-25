require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'daemons'
require 'amqp'

ENV['RAILS_ENV'] ||= 'production'

options = {
  :ontop => false,
  :backtrace => true,
  :dir_mode => :normal,
  :dir => File.join(configatron.amqp_rails_worker.rails_root, 'tmp/pids'),
  :log_dir => File.join(configatron.amqp_rails_worker.rails_root, 'log'),
  :log_output => true
}

Daemons.run_proc(configatron.amqp_rails_worker.name, options) do
  require File.join(configatron.amqp_rails_worker.rails_root, 'config/environment.rb')

  logger = Logger.new(Rails.root.join("log/#{configatron.amqp_rails_worker.name}.log"))
  logger.formatter = Logger::Formatter.new
  Rails.logger = logger

  EventMachine.run do
    connection = AMQP.connect(configatron.amqp_rails_worker.amqp.connection_parameters)

    connection.on_error do |conn, connection_close|
      logger.info "[connection.close] Reply code = #{connection_close.reply_code}, reply text = #{connection_close.reply_text}"
      if connection_close.reply_code == 320
        logger.info '[connection.close] Setting up a periodic reconnection timer...'
        # every 30 seconds
        conn.periodically_reconnect(30)
      end
    end

    connection.on_connection_interruption do |conn|
      logger.info 'Connection detected connection interruption'
    end

    channel = AMQP::Channel.new(connection, :auto_recovery => true)
    channel.prefetch(1)

    channel.auto_recovery = true
    channel.on_error do |ch, channel_close|
      raise "Channel error #{channel_close.reply_text}"
    end

    if channel.auto_recovering?
      logger.info "Channel #{channel.id} IS auto-recovering"
    end

    connection.on_tcp_connection_loss do |conn, settings|
      logger.info '[network failure] Trying to reconnect...'
      conn.reconnect(false, 2)
    end

    queue = channel.queue(configatron.amqp_rails_worker.amqp.queue_name, :durable => true, :auto_delete => false, :exclusive => false)
    logger.info 'Ready.'

    subscribe_to_queue_and_process_messages(queue, logger)

    show_stopper = Proc.new {
      connection.disconnect {
        logger.info 'Disconnected and exiting...'
        EventMachine.stop
      }
    }

    Signal.trap 'TERM', show_stopper
    Signal.trap 'INT', show_stopper

  end
end
