# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'bundler'
require 'json'
require 'sinatra/cross_origin'
require "httparty"
require "./emoji"
require './register'

Bundler.require

configure do
  enable :cross_origin
end

set :protection, :except => :frame_options

before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
          'Access-Control-Allow-Headers' => ['Content-Type', 'X-Frame-Options', 'Accept', 'X-Requested-With', 'access_token']

end

error do 
  content_type :json
  status 200 # or whatever

  e = env['sinatra.error']
  {:error => e.message}.to_json
end

get '/' do
  send_file File.join('public/', 'index.html')
end


post "/" do 
  content_type :json

  #READ REQ BODY
  body = JSON.parse(request.body.read)

  #HOLDS PREHEADER REQUEST
  preheader = params[:type]

 #Error property doesnt exist
  unless body.has_key?("subject")
    return { :error => "Missing subject property" }.to_json
  end

  #Error message is empty
  unless body["subject"].length.to_i > 0
    return { :error => "empty message" }.to_json
  end

  subject = body['subject'].to_s.downcase
  result = []
  status = "Good"

  #CLEAN STRING
  #subject.gsub!(/\-/, ' ')
  #subject.gsub!(/\"/, '')
 
  #LENGTH RULE
  if subject.size.to_i > 50 
    other = Hash.new
    other[:word] = "Lengde (" + subject.size.to_s + " tegn > 50 tegn). Din tekst inneholder " + subject.size.to_s + " tegn."
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Vurder og kort ned teksten til rundt 50 tegn."

    result << other
  end

  #COUNT WORDS
  words = subject.to_s.split(" ")

  if words.length.to_i < 5
    other = Hash.new
    other[:word] = "Antall ord"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Teksten bør bestå av 5 - 8 ord."
   
    result << other
  end

  if words.length.to_i > 7
    other = Hash.new
    other[:word] = "Antall ord"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Teksten bør bestå av 5 - 8 ord (pga åpning på mobil)."
   
    result << other
  end

  #MIN LENGTH RULE
  if subject.size.to_i <= 10
    other = Hash.new
    other[:word] = "Antall tegn"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Teksten er avgjørende for om e-posten åpnes eller ikke. Gi en mer detaljert beskrivelse om hva e-posten omhandler."
   
    result << other
  end 

  #SPECIAL CHARS
  if subject.to_s =~ /[\@\$\^\%\&\~\*\[\]\|\{\}]/
    other = Hash.new
    other[:word] = "Spesialtegn (@#$^%&~*)"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Økt spamfare. Ikke bruk spesialtegn hvis du absolutt ikke må."

    result << other
  end

  if subject.to_s =~ /#/
    other = Hash.new
    other[:word] = "# (Hashtag)"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Dette fremstår som relativt utdatert."

    result << other
  end

  #CATASTROF
  if subject.to_s =~ /^(Re:|Fwd:|fw:|Reminder:)/i
    other = Hash.new
    other[:word] = "Sikker kilde (Re:, Fwd:, Fw:, Reminder:)"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Økt spamfare. Ikke utgi deg for å være en sikker kilde. La SPF og DKIM gjøre den jobben."

    result << other
  end

  #EXCLAMATION RULE
  if subject.to_s =~ /\!{1,}/
    other = Hash.new
    other[:word] = "Utropstegn"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Oppfattes som skrikende og spamete. Bruk av utropstegn virker mot sin hensikt."

    subject.gsub!(/[\!]+/, '')

    result << other
  end

  #CAPS RULE
  if subject.to_s =~ /[A-Z]{2,}?/
    other = Hash.new
    other[:word] = "CAPS LOCK"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Oppfattes som skrikende og spamete. Bruk kun stor bokstav i starten av setninger."

    result << other
  end

  #PERCENTAGE RULE
  if subject.to_i =~ /[0-9]{0,3}%/
    other = Hash.new
    other[:word] = "0-100%"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Økt spamfare. Unngå for mange av disse advarslene i kombinasjon."

    result << other
  end

  #PERCENTAGE RULE
  if subject.to_s == "Kort innholdsbeskrivelse her"
    other = Hash.new
    other[:word] = "Kort innholdsbeskrivelse her"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Dette er en standardtekst. Gi en beskrivelse av innholdet istedenfor."

    result << other
  end

  #KR RULE
  if subject.to_s =~ /((?:kr)(?:\.)?(?:\s)?(?:\.)?(?:[0-9]+))|([0-9]+(?:\s)?(?:kr))|[0-9]+(?=\,)/
    other = Hash.new
    other[:word] = "0-1.000.000 kr"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Økt spamfare. Unngå å kombinere disse med tilsvarende advarsler."

    result << other
  end

  if subject.to_s =~ /^Se webversjon/
    other = Hash.new
    other[:word] = "Standardtekst"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Bruk preheader til å beskrive innholdet i e-posten."

    result << other
  end

  #CHECK IF STRING CONTAIN EMOJI
  if !preheader
    message = Message.new
    type    = message.get_type(subject)
    other = Hash.new

    if type.to_s != 'unicode' 
      other[:word] = "Emnet inneholder ikke emoijs"
      other[:status] = "info-circle analyzer-blue"
      other[:comment] = "Det kan være fordelaktig for åpningsraten å bruke emoijs."

      result << other
    end
  end

  subject = subject.downcase
  arr = subject.split(" ")
  
  #WORD RULES
  if arr.size > 0 
    arr.each { | word |
      Register::KNOWN.each do |bad|
        regEx = bad[:word] + "[e]?[r]?[e]?"
       
        if word =~ /#{regEx}/
          ha = Hash.new
          
          if bad[:plural]
            ha['word'] = bad[:word] + ", " + bad[:word] + "e, " + bad[:word] + "er, " + bad[:word] + "ere"
          else 
            ha['word'] = bad[:word]
          end

          ha[:status] = bad[:state]
          ha['comment'] = bad[:comment]

          result << ha
          break
        end
      end
    }
  else
    other = Hash.new
    other[:word] = subject
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Teksten er være avgjørende for om e-posten åpnes eller ikke. Gi en mer detaljert beskrivelse om hva e-posten omhandler."
   
    result << other
  end

  if result.size == 0
    #DO NOTHING
  end

  { :result => result }.to_json
 end


