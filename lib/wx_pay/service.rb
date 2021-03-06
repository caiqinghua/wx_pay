require 'rest_client'
require 'active_support/core_ext/hash/conversions'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com/pay'

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    def self.invoke_unifiedorder(params, _app_id = WxPay.appid, _mch_id = WxPay.mch_id, _mch_api_key = WxPay.key)
      params = {
        appid: _app_id,
        mch_id: _mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      params[:sign] = WxPay::Sign.generate(params, _mch_api_key)

      r = invoke_remote("#{GATEWAY_URL}/unifiedorder", make_payload(params))

      yield r if block_given?

      r
    end
    
    GENERATE_JSAPI_PAY_REQ_REQUIRED_FIELDS = %i(appId timeStamp nonceStr package signType)
    def self.generate_jsapi_pay_req(_prepay_id, _app_id = WxPay.appid, _mch_api_key = WxPay.key)
      params = {
        appId: _app_id,
        timeStamp: Time.now.to_i.to_s,
        nonceStr: SecureRandom.uuid.tr('-', ''),
        package: "prepay_id=#{_prepay_id}",
        signType: "MD5"
      }

      check_required_options(params, GENERATE_JSAPI_PAY_REQ_REQUIRED_FIELDS)

      params[:paySign] = WxPay::Sign.generate(params, _mch_api_key)

      params
    end

    GENERATE_APP_PAY_REQ_REQUIRED_FIELDS = %i(prepayid noncestr)
    def self.generate_app_pay_req(params, _app_id = WxPay.appid, _mch_id = WxPay.mch_id, _mch_api_key = WxPay.key)
      params = {
        appid: _app_id,
        partnerid: _mch_id,
        package: 'Sign=WXPay',
        timestamp: Time.now.to_i.to_s
      }.merge(params)

      check_required_options(params, GENERATE_APP_PAY_REQ_REQUIRED_FIELDS)

      params[:sign] = WxPay::Sign.generate(params, _mch_api_key)

      params
    end

    private

    def self.check_required_options(options, names)
      names.each do |name|
        warn("WxPay Warn: missing required option: #{name}") unless options.has_key?(name)
      end
    end

    def self.make_payload(params)
      "<xml>#{params.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}</xml>"
    end

    def self.invoke_remote(url, payload)
      r = RestClient::Request.execute(
        {
          method: :post,
          url: url,
          payload: payload,
          headers: { content_type: 'application/xml' }
        }.merge(WxPay.extra_rest_client_options)
      )

      if r
        WxPay::Result.new Hash.from_xml(r)
      else
        nil
      end
    end
  end
end
