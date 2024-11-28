require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TrucoRuby
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true
    config.time_zone = 'Brasilia'
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # Substitua '*' pela origem específica, se necessário (ex.: 'http://localhost:3000')
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end
  end
end
