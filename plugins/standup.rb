require 'tzinfo'

class Standup < CampfireBot::Plugin
  on_command 'shuffle', :shuffle
  
  def shuffle(msg)
    out = ["Dan","Eddy","Glenn","Prasanth"].shuffle
    tz = TZInfo::Timezone.get('America/Los_Angeles')
    local = tz.utc_to_local(Time.now.utc)

    s = local.strftime("Daily Standup Meeting - %m/%d/%Y %I:%M%p") + "\n\n"
    
    out.each do |victim|
      s += "#{victim}\n"
      s += "  Y: - \n"
      s += "  T: - \n\n"
    end
    
    msg.paste(s)
  end

end
