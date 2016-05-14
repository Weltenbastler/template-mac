include Nanoc::Helpers::LinkTo
include Nanoc::Helpers::Rendering

class Cached
  def self.wikis=(wikis)
    @@wikis = wikis
  end
  
  def self.wikis
    @@wikis ||= nil
  end
end
