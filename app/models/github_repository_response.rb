class GithubRepositoryResponse
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor *%i(
    is_success items
    rate_limit rate_limit_remaining rate_limit_reset
    current_page has_next_page
  )

  def self.parse(response, current_page)
    new.tap do |r|
      body = JSON.parse(response.body)
      header = response.headers

      r.is_success = response.success?
      check_body_hash_array_is_string =
        body[0].nil? && body != [] ? true : false
      r.items =
        if check_body_hash_array_is_string && body['tree'].present?
          body['tree'].map { |v| HashObject.new(v) }
        elsif check_body_hash_array_is_string && body['message'].present?
          # コミットファイル0件時 Not Found と返される際の対応
          r.is_success = true if body['message'] == 'Not Found'
          []
        else
          body.map { |v| HashObject.new(v) }
        end
      r.rate_limit = header['x-ratelimit-limit'].to_i
      r.rate_limit_remaining = header['x-ratelimit-remaining'].to_i
      r.rate_limit_reset = header['x-ratelimit-reset']

      r.current_page = current_page
      links = header['Link']
      r.has_next_page = false
      if links.present?
        r.has_next_page = links.split(',')[0].split(';')[1].include?('next')
      end
    end
  end

  def self.parse_blob(response)
    new.tap do |r|
      body = response.body
      header = response.headers

      r.is_success = response.success?
      r.items = body
      r.rate_limit = header['x-ratelimit-limit'].to_i
      r.rate_limit_remaining = header['x-ratelimit-remaining'].to_i
      r.rate_limit_reset = header['x-ratelimit-reset']
      r.current_page = 1
      r.has_next_page = false
    end
  end
end
