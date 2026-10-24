# Servicio Rack simple para simular la recepción de órdenes por parte de una tienda
# Levantar con: bundle exec rackup store_simulator/config.ru -p 3001
require 'json'

# Probabilidades configurables vía ENV
ERROR_PROB = ENV.fetch('STORE_ERROR_PROB', '0.20').to_f
DELAY_PROB = ENV.fetch('STORE_DELAY_PROB', '0.20').to_f
DELAY_MIN  = ENV.fetch('STORE_DELAY_MIN',  '10').to_i
DELAY_MAX  = ENV.fetch('STORE_DELAY_MAX',  '40').to_i

JSON_HEADERS = { 'content-type' => 'application/json' }.freeze

app = lambda do |env|
  req = Rack::Request.new(env)

  if req.post? && req.path_info =~ %r{\A/stores/([^/]+)/orders\z}
    store_code = Regexp.last_match(1)
    body = begin
      JSON.parse(req.body.read)
    rescue JSON::ParserError
      {}
    end

    # Caso 1 - Error de servidor instantáneo con probabilidad configurable
    if rand < ERROR_PROB
      return [500, JSON_HEADERS, [{ status: 'error', message: 'Error de servidor instantáneo' }.to_json]]
    end

    # Caso 2 - Demora aleatoria entre DELAY_MIN y DELAY_MAX segundos con probabilidad configurable
    if rand < DELAY_PROB
      delay = rand(DELAY_MIN..DELAY_MAX)
      sleep(delay)
      return [200, JSON_HEADERS, [{ status: 'ok', store: store_code, order_id: body['order_id'], delayed: true, delay_seconds: delay }.to_json]]
    end

    # Caso de respuesta normal
    [200, JSON_HEADERS, [{ status: 'ok', store: store_code, order_id: body['order_id'] }.to_json]]
  else
    [404, JSON_HEADERS, [{ error: 'not_found' }.to_json]]
  end
end

run app
