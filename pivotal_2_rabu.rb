require 'rubygems'
require 'hpricot'
require 'pivotal_adapter'  
require 'rabu_adapter'  

class Pivotal2Rabu
  include PivotalAdapter
  include RabuAdapter  
    def past_2_rabu(token, project)
      pivotal_iterations = get_done(token, project)
      rabu_iterations = convert_2_rabu(pivotal_iterations)
      # todo 2 json
    end
    
end

