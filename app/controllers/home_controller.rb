class HomeController < ApplicationController
  before_action :authenticate_owner!
  before_action :authenticate_hue, except: [:install, :auth]
  before_action :set_uri, only: [:switch_on, :switch_off, :trigger_bri_rotation, :change_light_state]
  
  require 'net/http'
  require 'base64'
  require 'net/https'
  require "uri"
  require 'digest/md5' 

  def install
    @hue_token = ENV['HUE_TOKEN']
  end
  
  def trigger_bri_rotation
    i = 0
    begin
       puts("Inside the loop i = #{i}" )
       sleep 0.2
       body = { 
         "bri": 200
       }
       req.body = body.to_json
       puts req.to_hash.inspect
       resp = http.request(req)
       puts resp
       
       sleep 1
       body = { 
         "bri": 240
       }
       req.body = body.to_json
       puts req.to_hash.inspect
       resp = http.request(req)
       puts resp
       i+=1
    end until i > 100
  end
  
  def index
    uri = URI.parse("https://api.meethue.com/bridge/#{ENV['HUE_USER']}/lights/3")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri, initheader = { 'Authorization' => "Bearer #{current_owner.hue_token}"})
    puts req.to_hash.inspect
    http.use_ssl = true
    resp = http.request(req)
    data = JSON.parse resp.body
    puts data
    @light = data["state"]
    @light["hue_percent"] = Home.calculate_val_from_hue(@light["hue"])
    @light["bri_percent"] = Home.calculate_val_from_bri(@light["bri"])
  end
  
  def get_username
    uri = URI.parse("https://api.meethue.com/bridge/0/config")
    http = Net::HTTP.new(uri.host, uri.port)
    body = { "linkbutton": true }
    req = Net::HTTP::Put.new(uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
    req.body = body.to_json
    http.use_ssl = true
    resp = http.request(req)
    puts resp
    puts resp.body
    puts "finished PUT"
    
    next_uri = URI.parse("https://api.meethue.com/bridge/")
    next_http = Net::HTTP.new(next_uri.host, next_uri.port)
    next_body = { "devicetype": "codaxe_home_lights" }
    next_req = Net::HTTP::Post.new(next_uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
    next_req.body = next_body.to_json
    next_http.use_ssl = true
    next_resp = next_http.request(next_req)
    puts next_resp.body
    # data = JSON.parse body
    # puts data.inspect
  end
  
  def auth
    uri = URI.parse("https://api.meethue.com/oauth2/token?code=#{params[:code]}&grant_type=authorization_code")

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    http.use_ssl = true
    resp = http.request(request)
    puts "Headers: #{resp.to_hash.inspect}"
    puts resp.to_hash["www-authenticate"]
    puts resp
    
    # nonce = resp.to_hash["www-authenticate"][0].split(",")[1].delete!('nonce=\"').tr(" ","")
    nonce = resp.to_hash["www-authenticate"][0].split(",")[1].split("=")[1].tr('\"','')
    realm = resp.to_hash["www-authenticate"][0].split(",")[0].split("=")[1].tr('\"','')
    puts nonce
    puts realm
    
    string_digest_1 = "#{ENV['HUE_TOKEN']}:#{realm}:#{ENV['HUE_SECRET']}"
    string_digest_2 = "POST:/oauth2/token"
    response_digest_1 = Digest::MD5.hexdigest(string_digest_1)
    response_digest_2 = Digest::MD5.hexdigest(string_digest_2)
    string_digest = "#{response_digest_1}:#{nonce}:#{response_digest_2}"
    response_digest = Digest::MD5.hexdigest(string_digest)
    puts "test start"
    
    authorization = [
      'username="'+ENV['HUE_TOKEN']+'"',
      'realm="'+realm+'"',
      'nonce="'+nonce+'"',
      'uri="/oauth2/token"',
      'response="'+ response_digest + '"'
    ].join(', ')
    
    puts authorization
    
    new_uri = URI.parse("https://api.meethue.com/oauth2/token?code=#{params[:code]}&grant_type=authorization_code")

    new_http = Net::HTTP.new(new_uri.host, new_uri.port)
    new_request = Net::HTTP::Post.new(new_uri.request_uri, initheader = { "Authorization" => "Digest #{authorization}" })
    
    puts "test prep"
    new_http.use_ssl = true
    puts new_request.to_hash.inspect
    new_resp = new_http.request(new_request)
    puts "Headers: #{new_resp.to_hash.inspect}"
    puts "test done"
    puts new_resp.body
    data = JSON.parse new_resp.body
    puts data.inspect
    puts new_resp
    puts new_resp.inspect
    current_owner.hue_token = data["access_token"]
    current_owner.hue_expiry = Time.now + Integer(data["access_token_expires_in"])
    current_owner.refresh_token = data["refresh_token"]
    current_owner.refresh_expiry = Time.now + Integer(data["refresh_token_expires_in"])
    if current_owner.save!
      puts "Success"
      redirect_to home_path
    else
      puts "Fail"
      redirect_to install_path
    end
  end
  
  def switch_on
    puts "on"
    puts params
    uri = URI.parse("https://api.meethue.com/bridge/#{ENV['HUE_USER']}/lights/3/state")
    http = Net::HTTP.new(uri.host, uri.port)
    body = { "on": true }
    req = Net::HTTP::Put.new(uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
    req.body = body.to_json
    puts req.to_hash.inspect
    http.use_ssl = true
    resp = http.request(req)
  end
  
  def switch_off
    puts "off"
    puts params
    uri = URI.parse("https://api.meethue.com/bridge/#{ENV['HUE_USER']}/lights/3/state")
    http = Net::HTTP.new(uri.host, uri.port)
    body = { "on": false }
    req = Net::HTTP::Put.new(uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
    req.body = body.to_json
    http.use_ssl = true
    resp = http.request(req)
    puts resp.body
  end
  
  def change_light_state
    puts uri.inspect
  end
  
  def change_color
    puts "change color"
    puts params
    hue_val = Home.calculate_hue(params[:value])
    uri = URI.parse("https://api.meethue.com/bridge/#{ENV['HUE_USER']}/lights/3/state")
    http = Net::HTTP.new(uri.host, uri.port)
    body = { "hue": hue_val }
    req = Net::HTTP::Put.new(uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
    req.body = body.to_json
    http.use_ssl = true
    resp = http.request(req)
    puts resp.body
  end
  
  def change_bright
    puts "change brightness"
    puts params
    hue_val = Home.calculate_bri(params[:value])
    uri = URI.parse("https://api.meethue.com/bridge/#{ENV['HUE_USER']}/lights/3/state")
    http = Net::HTTP.new(uri.host, uri.port)
    body = { "bri": hue_val }
    req = Net::HTTP::Put.new(uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
    req.body = body.to_json
    http.use_ssl = true
    resp = http.request(req)
    puts resp.body
  end
  
  def toggle_light
      
  end
  
  private
  
  def authenticate_hue
    # current_owner = Owner.first
    if current_owner.hue_token.blank?
      redirect_to install_path
    end
  end
  
  def set_uri 
    uri = URI.parse("https://api.meethue.com/bridge/#{ENV['HUE_USER']}/lights/3/state")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Put.new(uri.request_uri, initheader = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{current_owner.hue_token}"})
  end
  
#     HUE_RANGE = 0..65535
#     SATURATION_RANGE = 0..255
#     BRIGHTNESS_RANGE = 0..255
#     COLOR_TEMPERATURE_RANGE = 153..500

#     # Unique identification number.
#     attr_reader :id

#     # Bridge the light is associated with
#     attr_reader :bridge

#     # A unique, editable name given to the light.
#     attr_accessor :name

#     # Hue of the light. This is a wrapping value between 0 and 65535.
#     # Both 0 and 65535 are red, 25500 is green and 46920 is blue.
#     attr_reader :hue

#     # Saturation of the light. 255 is the most saturated (colored)
#     # and 0 is the least saturated (white).
#     attr_reader :saturation

#     # Brightness of the light. This is a scale from the minimum
#     # brightness the light is capable of, 0, to the maximum capable
#     # brightness, 255. Note a brightness of 0 is not off.
#     attr_reader :brightness

#     # The x coordinate of a color in CIE color space. Between 0 and 1.
#     #
#     # @see http://developers.meethue.com/coreconcepts.html#color_gets_more_complicated
#     attr_reader :x

#     # The y coordinate of a color in CIE color space. Between 0 and 1.
#     #
#     # @see http://developers.meethue.com/coreconcepts.html#color_gets_more_complicated
#     attr_reader :y

#     # The Mired Color temperature of the light. 2012 connected lights
#     # are capable of 153 (6500K) to 500 (2000K).
#     #
#     # @see http://en.wikipedia.org/wiki/Mired
#     attr_reader :color_temperature

#     # The alert effect, which is a temporary change to the bulb’s state.
#     # This can take one of the following values:
#     # * `none` – The light is not performing an alert effect.
#     # * `select` – The light is performing one breathe cycle.
#     # * `lselect` – The light is performing breathe cycles for 30 seconds
#     #     or until an "alert": "none" command is received.
#     #
#     # Note that in version 1.0 this contains the last alert sent to the
#     # light and not its current state. This will be changed to contain the
#     # current state in an upcoming patch.
#     #
#     # @see http://developers.meethue.com/coreconcepts.html#some_extra_fun_stuff
#     attr_reader :alert

#     # The dynamic effect of the light, can either be `none` or
#     # `colorloop`. If set to colorloop, the light will cycle through
#     # all hues using the current brightness and saturation settings.
#     attr_reader :effect

#     # Indicates the color mode in which the light is working, this is
#     # the last command type it received. Values are `hs` for Hue and
#     # Saturation, `xy` for XY and `ct` for Color Temperature. This
#     # parameter is only present when the light supports at least one
#     # of the values.
#     attr_reader :color_mode

#     # A fixed name describing the type of light.
#     attr_reader :type

#     # The hardware model of the light.
#     attr_reader :model

#     # An identifier for the software version running on the light.
#     attr_reader :software_version

#     # Reserved for future functionality.
#     attr_reader :point_symbol

#     def initialize(client, bridge, id, hash)
#       @client = client
#       @bridge = bridge
#       @id = id
#       unpack(hash)
#     end

#     def name=(new_name)
#       unless (1..32).include?(new_name.length)
#         raise InvalidValueForParameter, 'name must be between 1 and 32 characters.'
#       end

#       body = {
#         :name => new_name
#       }

#       uri = URI.parse(base_url)
#       http = Net::HTTP.new(uri.host)
#       response = http.request_put(uri.path, JSON.dump(body))
#       response = JSON(response.body).first
#       if response['success']
#         @name = new_name
#       # else
#         # TODO: Error
#       end
#     end

#     # Indicates if a light can be reached by the bridge. Currently
#     # always returns true, functionality will be added in a future
#     # patch.
#     def reachable?
#       @state['reachable']
#     end

#     # @param transition The duration of the transition from the light’s current
#     #   state to the new state. This is given as a multiple of 100ms and
#     #   defaults to 4 (400ms). For example, setting transistiontime:10 will
#     #   make the transition last 1 second.
#     def set_state(attributes, transition = nil)
#       body = translate_keys(attributes, STATE_KEYS_MAP)

#       # Add transition
#       body.merge!({:transitiontime => transition}) if transition

#       uri = URI.parse("#{base_url}/state")
#       http = Net::HTTP.new(uri.host)
#       response = http.request_put(uri.path, JSON.dump(body))
#       JSON(response.body)
#     end

#     # Refresh the state of the lamp
#     def refresh
#       json = JSON(Net::HTTP.get(URI.parse(base_url)))
#       unpack(json)
#     end

#   private

#     KEYS_MAP = {
#       :state => :state,
#       :type => :type,
#       :name => :name,
#       :model => :modelid,
#       :software_version => :swversion,
#       :point_symbol => :pointsymbol
#     }

#     STATE_KEYS_MAP = {
#       :on => :on,
#       :brightness => :bri,
#       :hue => :hue,
#       :saturation => :sat,
#       :xy => :xy,
#       :color_temperature => :ct,
#       :alert => :alert,
#       :effect => :effect,
#       :color_mode => :colormode,
#       :reachable => :reachable,
#     }

#     def unpack(hash)
#       unpack_hash(hash, KEYS_MAP)
#       unpack_hash(@state, STATE_KEYS_MAP)
#       @x, @y = @state['xy']
#     end

    # def base_url
    #   "http://#{@bridge.ip}/api/#{@client.username}/lights/#{id}"
    # end
end