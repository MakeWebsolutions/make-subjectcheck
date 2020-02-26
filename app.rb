# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'bundler'
require 'json'
require 'sinatra/cross_origin'
require "httparty"
require "./emoji"
require './register'
require './powerwords'

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

  subject = body['subject']
  result = []
  status = "Good"

  #CLEAN STRING
  #subject.gsub!(/\-/, ' ')
  #subject.gsub!(/\"/, '')

   #CAPS RULE
  if subject.to_s =~ /[A-Z]{2,}?/
    other = Hash.new
    other[:word] = "CAPS LOCK"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Oppfattes som skrikende og spamete. Bruk kun stor bokstav i starten av setninger (Viktig)."

    result << other
  end

  subject = subject.to_s.downcase
 
  #LENGTH RULE
  if !preheader
    if subject.size.to_i > 60 
      other = Hash.new
      other[:word] = "Lengde. Din tekst inneholder " + subject.size.to_s + " tegn."
      other[:status] = "exclamation-triangle analyzer-orange"
      other[:comment] = "Vær oppmerksom på at teksten vil bli kuttet på mobil"

      result << other
    end

    #COUNT WORDS
    words = subject.to_s.split(" ")

    if words.length.to_i < 5
      other = Hash.new
      other[:word] = "Antall ord"
      other[:status] = "exclamation-triangle analyzer-orange"
      other[:comment] = "Du kan godt bruke flere ord og ta litt mer plass."
     
      result << other
    end

    if words.length.to_i >= 9
      other = Hash.new
      other[:word] = "Antall ord"
      other[:status] = "exclamation-triangle analyzer-orange"
      other[:comment] = "Vær oppmerksom på at teksten vil bli kuttet på mobil"
     
      result << other
    end
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

  #MARKED HASTAG AS OLD
  if subject.to_s =~ /#/
    other = Hash.new
    other[:word] = "# (Hashtag)"
    other[:status] = "exclamation-triangle analyzer-orange"
    other[:comment] = "Dette fremstår som relativt utdatert."

    result << other
  end

  #CATASTROF
  if subject.to_s =~ /(re\s?\:|fwd\s?\:|fw\s?\:|reminder\s?\:)/i
    other = Hash.new
    other[:word] = "Sikker kilde (Re:, Fwd:, Fw:, Reminder:)"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Økt spamfare. Ikke utgi deg for å være en sikker kilde."

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

  #PREHEADER STARTS WITH SE WEBVERSJON
  if subject.to_s =~ /^se\swebversjon/ || subject.to_s =~ /^sjå\swebversjon/ || subject.to_s =~ /^view\swebversion/ || subject.to_s =~ /^läs\spå\swebben/ || subject.to_s =~ /^se\swebversion/
    other = Hash.new
    other[:word] = "Standardtekst"
    other[:status] = "times-circle analyzer-red"
    other[:comment] = "Du bør legge til en preheader."

    result << other
  end

  #FIRST 50 CHARS CONTAIN SE WEBVERSJON
  if preheader
    if subject.slice(0,50) =~ /se\swebversjon/ || subject.slice(0,50) =~ /sjå\swebversjon/ || subject.slice(0,50) =~ /view\swebversion/ || subject.to_s =~ /läs\spå\swebben/ || subject.to_s =~ /se\swebversion/
      other = Hash.new
      other[:word] = "Preheader"
      other[:status] = "exclamation-triangle analyzer-orange"
      other[:comment] = "Preheaderen er litt kort."

      result << other
    end
  end

  #ADD RULES FOR MAILCHIMP, MAILMOJO AND APSIS PREHEADERS HERE

  ##################################################
  # RULES #
  ##################################################

  #CHECK IF STRING CONTAIN EMOJI
  if !preheader
    message = Message.new
    type    = message.get_type(subject)
    other = Hash.new

    if type.to_s != 'unicode' 
      other[:word] = ""
      other[:status] = "info-circle analyzer-blue"
      other[:comment] = "Vurder og frisk opp emnetfeltet med emoijs 😃😃😃"

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
          
          ha['word'] = bad[:word]
          ha['status'] = bad[:state]
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

  if arr.size > 0 
    arr.each { | word | 
      Powerwords::KNOWN.each do | powerword |
        if powerword[:word].to_s == word.to_s
          ha = Hash.new
          ha['word'] = powerword[:word]
          ha['status'] = powerword[:state]
          ha['comment'] = powerword[:comment]

          result << ha
          break
        end
      end
    }
  end

  if result.size == 0
    #DO NOTHING
  end

  { :result => result }.to_json
 end


