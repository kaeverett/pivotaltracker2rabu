require 'rubygems'
require 'hpricot'
module PivotalAdapter
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
      iterations = get_iterations(token, project, 'backlog')
    end

    def get_done(token, project)
      iterations = get_iterations(token, project, 'done')
    end

    # iterations = backlog | done | current
    def get_iterations(token, project, interations, limit = false)
      limit_arg = limit ? "?limit=5" : ""
      response = `curl -H "X-TrackerToken: #{token}" -X GET http://www.pivotaltracker.com/services/v3/projects/#{project}/iterations/#{interations}#{limit_arg}`
      iterations = nil
      begin
        doc = Hpricot(response).at('iterations') 
        iterations = parse_iterations(doc)
      rescue StandardError => e
        fail_gracefully e, response, "get pivotaltracker iterations. verify project id"
      end
      iterations
    end

    def parse_iterations(doc)
      rabu = {}
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
      iterations
    end
  
    def parse_stories(doc)
      stories = []
      doc.search('story').each do |s|
        story = {
          :story_type => s.at('story_type').innerHTML,
          :url => s.at('url').innerHTML,
          :name => s.at('name').innerHTML,
          :created_at => get_time(s.at('created_at').innerHTML),
          :updated_at => get_time(s.at('updated_at').innerHTML)
        }
        story[:estimate] = s.at('estimate').innerHTML if s.at('estimate')
        story[:owned_by] = s.at('owned_by').innerHTML if s.at('owned_by')
        stories << story
      end
      stories
    end

    # given 2010/07/28 15:14:25 PDT return Time
    def get_time(date_string)
      begin
        s1 = date_string.split '/'
        yr = s1[0]
        mon = s1[1]
        s2 = s1[2].split ' '  # 28 15:14:25 PDT
        dy = s2[0]
        times = s2[1].split ':'
        hr = times[0]
        min = times[1]
        sec = times[2]
      rescue StandardError => e
        p "invalid time format: #{date_string}. ignoring"
        return nil
      end
      Time.mktime yr, mon, dy, hr, min, sec
    end

    def fail_gracefully(stderr, response, action)
      p "unable to #{action}: #{response}"
      # p stderr.message  
      # p stderr.backtrace.inspect
      exit false
    end
end

