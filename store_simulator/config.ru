# Servicio Rack simple para simular la recepción de órdenes por parte de una tienda
# Levantar con: bundle exec rackup store_simulator/config.ru -p 3001
require 'json'

# Probabilidades configurables vía ENV
ERROR_PROB = ENV.fetch('STORE_ERROR_PROB', '0.20').to_f
DELAY_PROB = ENV.fetch('STORE_DELAY_PROB', '0.20').to_f
DELAY_MIN  = ENV.fetch('STORE_DELAY_MIN',  '10').to_i
DELAY_MAX  = ENV.fetch('STORE_DELAY_MAX',  '40').to_i

PROCESSED = {}

app = lambda do |env|
  req = Rack::Request.new(env)

  if req.post? && req.path_info =~ %r{\A/stores/([^/]+)/orders\z}
    store_code = Regexp.last_match(1)
    body = begin
      JSON.parse(req.body.read)
    rescue JSON::ParserError
      {}
    end

    headers = { 'content-type' => 'application/json' }
    order_id = body['order_id']
    key = "#{store_code}:#{order_id}"

    if order_id && PROCESSED[key]
      return [200, headers, [{ status: 'ok', store: store_code, order_id: order_id, duplicate: true }.to_json]]
    end

    # Caso 1 - Error de servidor instantáneo con probabilidad configurable
    if rand < ERROR_PROB
      return [500, headers, [{ status: 'error', message: 'Error de servidor instantáneo' }.to_json]]
    end

    # Caso 2 - Demora aleatoria entre DELAY_MIN y DELAY_MAX segundos con probabilidad configurable
    if rand < DELAY_PROB
      delay = rand(DELAY_MIN..DELAY_MAX)
      sleep(delay)
      PROCESSED[key] = true if order_id
      return [200, headers, [{ status: 'ok', store: store_code, order_id: order_id, delayed: true, delay_seconds: delay }.to_json]]
    end

    PROCESSED[key] = true if order_id
    # Caso de respuesta normal
    [200, headers, [{ status: 'ok', store: store_code, order_id: order_id }.to_json]]
  else
    [404, { 'content-type' => 'application/json' }, [{ error: 'not_found' }.to_json]]
  end
end

run app
