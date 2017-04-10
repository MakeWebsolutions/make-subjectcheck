# Require the bundler gem and then call Bundler.require to load in all gems
# listed in Gemfile.
require 'bundler'
require 'json'
require 'sinatra/cross_origin'
require './register.rb'

Bundler.require

configure do
  enable :cross_origin
end

before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
          'Access-Control-Allow-Headers' => ['Content-Type', 'Accept', 'X-Requested-With', 'access_token']

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
  params = JSON.parse(request.body.read)

  subject = params['subject']
  result = []
  status = "Good"

  #CLEAN STRING
  subject.gsub!(/\-/, ' ')
  subject.gsub!(/\"/, '')

  #LENGTH RULE
  if subject.size > 80 
    other = Hash.new
    other[:word] = "Lengde (" + subject.size.to_s + " tegn > 78 tegn)"
    other[:status] = "warning"
    other[:comment] = "Kan føre til scrolling i emnefeltet. Vurder omformulering."

    result << other
  end

  #MIN LENGTH RULE
  if subject.size <= 15
    other = Hash.new
    other[:word] = subject
    other[:status] = "warning"
    other[:comment] = "Emne er avgjørende for om mailen åpnes eller ikke. Gi en mer detaljert beskrivelse om hva mailen omhandler."
   
    result << other
  end 

  #SPECIAL CHARS
  if subject =~ /[\@\#\$\^\%\&\~\*]/
    other = Hash.new
    other[:word] = "Spesialtegn (@#$^%&~*)"
    other[:status] = "warning"
    other[:comment] = "Økt spamfare. Ikke bruk dem hvis du absolutt ikke må."

    result << other
  end

  #CATASTROF
  if subject =~ /^(Re:|Fwd:|fw:|Reminder:)/i
    other = Hash.new
    other[:word] = "Sikker kilde (re:, fwd:)"
    other[:status] = "danger"
    other[:comment] = "Økt spamfare. Ikke utgi deg for å være en sikker kilde. La SPF og DKIM gjøre den jobben."

    result << other
  end

  #EXCLAMATION RULE
  if subject =~ /\!{1,}/
    other = Hash.new
    other[:word] = "Utropstegn"
    other[:status] = "danger"
    other[:comment] = "Oppfattes som skrikende og spamete. Bruk av utropstegn virker mot sin hensikt."

    subject.gsub!(/[\!]+/, '')

    result << other
  end

  #CAPS RULE
  if subject =~ /[A-Z]{3,}?/
    other = Hash.new
    other[:word] = "CAPS LOCK"
    other[:status] = "danger"
    other[:comment] = "Oppfattes som skrikende og spamete. Bruk kun stor bokstav i starten av setninger."

    result << other
  end

  #PERCENTAGE RULE
  if subject =~ /[0-9]{0,2}%/
    other = Hash.new
    other[:word] = "0-100%"
    other[:status] = "warning"
    other[:comment] = "Økt spamfare. Unngå for mange av disse advarslene i kombinasjon."

    result << other
  end

  #KR RULE
  if subject =~ /((?:kr)(?:\.)?(?:\s)?(?:\.)?(?:[0-9]+))|([0-9]+(?:\s)?(?:kr))|[0-9]+(?=\,)/
    other = Hash.new
    other[:word] = "0-1.000.000 kr"
    other[:status] = "warning"
    other[:comment] = "Økt spamfare. Unngå å kombinere disse med tilsvarende advarsler."

    result << other
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
    other[:status] = "warning"
    other[:comment] = "Emne er være avgjørende for om mailen åpnes eller ikke. Gi en mer detaljert beskrivelse om hva mailen omhandler."
   
    result << other
  end

  if result.size == 0
    other = Hash.new
    other[:word] = ""
    other[:status] = "success"
    other[:comment] = "Ingenting å utsette på dette emnefeltet!"

    result << other
  end
  
  { :result => result }.to_json
 end


