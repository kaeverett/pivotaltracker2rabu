require 'rubygems'
require 'hpricot'
class Pivotal2Rabu
  
    # <?xml version='1.0' encoding='UTF-8'?>
    # <token>
    #   <guid>2c71bec27843c1d84b3bdd547f3</guid>
    #   <id type="integer">1</id>
    # </token>  
    def get_token(user, pass)
      response = `curl -u #{user}:#{pass} -X GET https://www.pivotaltracker.com/services/v3/tokens/active`
      token = nil
      if response.include? 'Access denied'
        p "unable to get token from pivotaltracker: #{response}"
        exit false
      end
      begin
        doc = Hpricot(response).at('token') 
        token = doc.at('guid').innerHTML
      rescue StandardErrror => e
        fail_gracefully e, response, "get pivotaltacker token.  verify user/password"
      end
      token
    end
  
    def get_backlog(token, project)
      get_iterations(token, project, 'backlog')
    end
  
    def get_done(token)
      get_iterations(token, project, 'done')
    end
  
    # iterations = backlog | done | current
    def get_iterations(token, project, interations, limit = false)
      limit_arg = limit ? "?limit=5" : ""
      response = `curl -H "X-TrackerToken: #{token}" -X GET http://www.pivotaltracker.com/services/v3/projects/#{project}/iterations/#{interations}#{limit_arg}`
      begin
        doc = Hpricot(response).at('iterations') 
        parse_iterations(doc)
      rescue StandardError => e
        fail_gracefully e, response, "get pivotaltracker iterations. verify project id"
      end
    end
    
    def parse_iterations(doc)
      iterations = []
      doc.search('iteration').each do |d| 
        iteration = {
          :number => d.at('number').innerHTML,
          :start => get_time(d.at('start').innerHTML),
          :finish => get_time(d.at('finish').innerHTML), 
          :stories => parse_stories(d)       
        }
        iterations << iteration
      end
    end
      
    def parse_stories(doc)
      stories = []
      doc.search('story').each do |s|
        story = {
          :story_type => s.at('story_type').innerHTML,
          :url => s.at('url').innerHTML,
          # :estimate => s.at('estimate').innerHTML if s.at('estimate')
          # :owned_by => s.at('owned_by').innerHTML if s.at('owned_by')
          :created_at => get_time(s.at('created_at').innerHTML),
          :updated_at => get_time(s.at('updated_at').innerHTML)          
        }
        stories << story
      end
      stories
    end
    
    # given 2010/07/28 15:14:25 PDT return Time
    def get_time(date_string)
      s1 = date_string.split '/'
      yr = s1[0]
      mon = s1[1]
      s2 = s1[2].split ' '  # 28 15:14:25 PDT
      dy = s2[0]
      times = s2[1].split ':'
      hr = times[0]
      min = times[1]
      sec = times[2]
    Time.mktime yr, mon, dy, hr, min, sec
  end

  private 
  
  def fail_gracefully(stderr, response, action)
    p "unable to #{action}: #{response}"
    # p stderr.message  
    # p stderr.backtrace.inspect
    exit false
  end
end

p2r = Pivotal2Rabu.new
user = ARGV[0]
pass = ARGV[1]
project = ARGV[2]
token = p2r.get_token user,pass
iterations = p2r.get_backlog(token, project)
p iterations.inspect
