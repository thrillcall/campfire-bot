require 'open-uri'

class Facepalms < CampfireBot::Plugin
  on_command 'facepalm', :facepalm
  
  FACEPALM_COUNT    = 11
  FACEPALM_BASE_URL = "http://s3.amazonaws.com/Thrillcall-FacebookCanvasHeaders-Development/facepalm/"
  
  def facepalm(msg)
    # Find random facepalm
    
    filename  = "facepalm-#{rand(FACEPALM_COUNT)}.jpg"
    url       = "#{FACEPALM_BASE_URL}#{filename}"
    
    msg.speak url
    
  rescue Exception => e
    msg.speak e
  end
end
