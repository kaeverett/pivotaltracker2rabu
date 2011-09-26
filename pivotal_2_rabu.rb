require 'pivotal_adapter'
require 'rabu_adapter'
require 'json'

# TODO
# - export scope added

class Pivotal2Rabu
  include PivotalAdapter
  include RabuAdapter  
    def convert(token, project)
      done = get_done(token, project)
      backlog = get_backlog(token, project)
      rabu_iterations = convert_2_rabu(done, backlog)
      rabu_iterations.to_json
    end
end

