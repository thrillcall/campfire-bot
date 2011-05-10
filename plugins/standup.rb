class Standup < CampfireBot::Plugin
  on_command 'shuffle', :shuffle
  
  def shuffle(msg)
    out = ["Dan","Eddy","Glenn","Noel","Prasanth"].shuffle
    msg.speak(out.to_s)
  end

end

