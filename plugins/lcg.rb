class Lcg < CampfireBot::Plugin
  on_command 'lcg', :lcg
  
  def lcg(msg)
    url = "http://www.youtube.com/watch?v=U5Xp1QY8pO0"
    msg.speak(url)
  end

end

