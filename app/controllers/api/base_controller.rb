require 'digest'

class Api::BaseController < ActionController::API
  private

  def idempotency_key_header
    request.headers['Idempotency-Key'] || request.headers['HTTP_IDEMPOTENCY_KEY']
  end

  def with_idempotency(raw_params = request.raw_post)
    key = idempotency_key_header
    return render_from_result(yield) unless key.present?

    key = key.to_s.strip
    request_hash = Digest::SHA256.hexdigest(raw_params.to_s)

    existing = IdempotencyKey.find_by(key: key)
    if existing
      if existing.expires_at < Time.current
        existing.destroy
      elsif existing.request_hash.present? && existing.request_hash != request_hash
        render json: { errors: ['Idempotency-Key conflict: request body differs'] }, status: :conflict
        return
      elsif existing.response_body.present?
        render json: JSON.parse(existing.response_body), status: existing.status_code || :created
        return
      end
    end

    result = yield
    if result.is_a?(Hash)
      status = result[:status] || :created
      body = result[:body] || {}
      IdempotencyKey.create!(
        key: key,
        request_hash: request_hash,
        order_id: body.is_a?(Hash) ? (body[:id] || body['id']) : nil,
        status_code: status,
        response_body: body.to_json,
        expires_at: 24.hours.from_now
      )
      render json: body, status: status
    else
      result
    end
  end

  def render_from_result(result)
    return result unless result.is_a?(Hash)

    status = result[:status] || :ok
    body = result[:body]
    if body.nil?
      head status
    else
      render json: body, status: status
    end
  end
end

