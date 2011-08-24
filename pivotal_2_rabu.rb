require 'pivotal_adapter'
require 'rabu_adapter'  

class Pivotal2Rabu
  include PivotalAdapter
  include RabuAdapter  
    def past_2_rabu(token, project)
      done = get_done(token, project)
      backlog = get_backlog(token, project)
      rabu_iterations = convert_2_rabu(done, backlog)
      # todo 2 json
    end
    
end

