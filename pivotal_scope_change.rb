require 'pivotal_adapter'
require 'json'

class PivotalScopeChange
  include PivotalAdapter
    def get_scope_change(token, project)
      done = get_done(token, project)
      backlog = get_backlog(token, project)
      current = get_current(token, project)
      change = parse_change_from_iterations(done, current, backlog)
      change
    end
end

def parse_change_from_iterations(done_pivotal_iterations, current_pivotal_iterations, backlog_pivotal_iterations)
  # NOTE:  current already included in backlog
  all_iterations = done_pivotal_iterations + backlog_pivotal_iterations
  change = []
  # include current in scope change report, so you can monitor new scope as it is added
  done_plus_current = done_pivotal_iterations + current_pivotal_iterations
  done_plus_current.each do |pi|
    s = scope(pi, all_iterations)
    c =  s[4]
    a =  s[0]
    r =  s[5]
    change << {
          :started => pi[:start].strftime("%b %d %Y"),
          :added => a,
          :remaining => r,
          :bugs => s[1],
          :features => s[2],
          :stories => s[3], 
          :completed => c,
          :velocity => c - a,
          :bugs_by_owner => s[6]
    }
  end
  # reverse list.  recent to oldest
  change
end

def scope_remaining_after_and_added_during(iteration_start_time, iteration_end_time, pivotal_iterations, current_iteration)
  remaining = 0
  added = 0 
  stories = []
  bugs_by_owner = {}
  bugs = 0
  features = 0
  completed = 0
  past_exluded = false
  # count all remaining/added stories still in scope and added during the sprint
  pivotal_iterations.each do |pi|
    # skip stories already completed in earlier sprints
    next if pi[:started] && pi[:started] < iteration_start_time 
    # count all stories created before (or during) the sprint, but completed after iterations
    pi[:stories].each do |s|
     if s[:name] == 'excluded' 
       past_exluded = true
       break
     end
     remaining += s[:estimate].to_i  if s[:created_at] && s[:estimate] && 
            # created before next iteration, and in a sprint after current sprint                    
            compare(s[:created_at], 'lte', iteration_end_time) && compare(pi[:start], 'gte', iteration_end_time)
     if s[:created_at] && s[:estimate] && 
            # created during iteration   
            compare(s[:created_at], 'gte', iteration_start_time) && compare(s[:created_at], 'lte', iteration_end_time)
       added += s[:estimate].to_i
       stories << "#{s[:estimate]}:#{s[:state]}:#{s[:name]}:#{s[:created_at].strftime('%b %d %Y')}"
     end
    end
    break if past_exluded
  end
  current_iteration[:stories].each do |s|
    next if s[:state] != 'accepted'
    completed += s[:estimate].to_i if s[:estimate].to_i && s[:updated_at] 
    if s[:story_type] == 'bug'
      bugs += s[:estimate].to_i if s[:estimate].to_i > 0
      bugs_by_owner = count_bug(bugs_by_owner, s)
    end
    features += s[:estimate].to_i if s[:story_type] == 'feature' && s[:estimate].to_i > 0
  end
  [added, bugs, features, stories, completed, remaining, bugs_by_owner]
end

def count_bug(bugs_by_owner, story)
  bugs_by_owner[story[:owned_by]] = 0 unless bugs_by_owner[story[:owned_by]] 
  bugs_by_owner[story[:owned_by]] += story[:estimate].to_i if story[:story_type] == 'bug'
  bugs_by_owner
end

def scope(pi, pivotal_iterations)
  scope_remaining_after_and_added_during(pi[:start], pi[:finish], pivotal_iterations, pi)
end

def compare(t1, operator = 'eq', t2 = nil)
  return round(t1) == round(t2) if operator == 'eq'
  return round(t1) > round(t2) if operator == 'gt'
  return round(t1) >= round(t2) if operator == 'gte'
  return round(t1) < round(t2) if operator == 'lt'
  return round(t1) <= round(t2) if operator == 'lte'
end

# default unit == day
def round(t, to_unit = (60 * 60 * 24))
  Time.at(t.to_i/(to_unit)*(to_unit))
end    

psc = PivotalScopeChange.new
user = ARGV[0]
pass = ARGV[1]
project = ARGV[2]
token = psc.get_token user,pass
change = psc.get_scope_change(token, project)
p "started, velocity, remaining, added, completed, bugs, features, stories added"
change.each do |i|
  puts "#{i[:started]},#{i[:velocity]}, #{i[:remaining]},#{i[:added]}, #{i[:completed]}, #{i[:bugs]}, #{i[:features]}, #{i[:stories].inspect}"
end