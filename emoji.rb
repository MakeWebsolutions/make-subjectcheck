require "sms_tools"

class Message
  def get_type(message)
    type = SmsTools::EncodingDetection.new message

    if type.encoding.to_s == "ascii"
      type = "gsm"
    else 
      type = type.encoding
    end

    return type
  end
end