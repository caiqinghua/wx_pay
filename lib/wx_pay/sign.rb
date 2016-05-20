require 'digest/md5'

module WxPay
  module Sign
    def self.generate(params, _mch_api_key = WxPay.key)
      query = params.sort.map do |key, value|
        "#{key}=#{value}"
      end.join('&')

      Digest::MD5.hexdigest("#{query}&key=#{_mch_api_key}").upcase
    end

    def self.verify?(params, _mch_api_key = WxPay.key)
      params = params.dup
      sign = params.delete('sign') || params.delete(:sign)

      generate(params, _mch_api_key) == sign
    end
  end
end
