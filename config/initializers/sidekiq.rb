# Sidekiq connects to Redis through REDIS_URL.
# The web process (enqueue) and the worker process (execute) must use the
# same Redis instance, otherwise jobs are enqueued but never processed.
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
