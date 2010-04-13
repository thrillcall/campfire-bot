module CampfireBot
  class Message < Hash
    def initialize(attributes)
      self.merge!(attributes)
      self[:message] = self['body']
      self[:person] = self['user']['name']
      self[:room] = attributes[:room]
    end
    
    def reply(str)
      speak(str)
    end
    
    def speak(str)
      self[:room].speak(str)
    end
    
    def paste(str)
      self[:room].paste(str)
    end
    
    def upload(file_path)
      self[:room].upload(file_path)
    end
  end
end