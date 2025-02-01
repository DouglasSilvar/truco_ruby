require "active_support/core_ext/integer/time"
require "logger"

Rails.application.configure do
  # Habilita o recarregamento de código sem reiniciar o servidor
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Configuração de cache para o ambiente de desenvolvimento
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Configuração de armazenamento ativo (Active Storage)
  config.active_storage.service = :local

  # Configuração de e-mails
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Configuração de logs e avisos de depreciação
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Configuração de Active Record
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Configuração de logs para Active Job
  config.active_job.verbose_enqueue_logs = true

  # Configuração para anotar os arquivos de view renderizados
  config.action_view.annotate_rendered_view_with_filenames = true

  # Levanta erro caso uma action de callback esteja faltando
  config.action_controller.raise_on_missing_callback_actions = true

  # Configuração de logs: apenas WARN, ERROR e FATAL serão exibidos
  config.logger = Logger.new($stdout) # Direciona os logs para o console
  config.logger.level = Logger::WARN  # Define o nível mínimo de log para WARN
  config.log_level = :warn # Redundante, mas garante a configuração correta
end
