module RabuAdapter
    def convert_2_rabu(done_pivotal_iterations, backlog_pivotal_iterations)
      rabu = history_2_rabu(done_pivotal_iterations, backlog_pivotal_iterations)
      rabu = add_milestones_2_rabu(rabu, done_pivotal_iterations, backlog_pivotal_iterations)
      rabu
    end

    def history_2_rabu(done_pivotal_iterations, backlog_pivotal_iterations)
      all_iterations = done_pivotal_iterations + backlog_pivotal_iterations
      rabu = {}
      rabu[:name] = 'pivotal project'
      rabu[:updated] = rabu_time_format Time.now
      rabu[:iterations] = []
      done_pivotal_iterations.each do |pi|
        length = length_of_iteration_in_days(pi[:start], pi[:finish])
        scope = scope(pi, all_iterations)
        rabu[:iterations] << {
              :started => rabu_time_format(pi[:start]),
              :length => length,
              :included => scope,
              :velocity => calculate_velocity(scope, rabu[:iterations])
        }
      end
      # reverse list.  recent to oldest
      rabu[:iterations] = rabu[:iterations].reverse
      rabu
    end

    def velocity_from_scope(scope)
      completed = scope[2][1]
      added = scope[1][1]
      return 0 unless completed && completed.is_a?(Integer) && added &&  added.is_a?(Integer)
      completed - added if @velocity_calculation == 'completed - added'
      completed         unless @velocity_calculation == 'completed - added'
    end

    # count amount (completed - added) avg over 3 sprints
    def calculate_velocity(scope, rabu_iterations)
      v = velocity_from_scope scope
      iteration_count = 1
      if rabu_iterations && rabu_iterations.size >= 2
        v += velocity_from_scope rabu_iterations[rabu_iterations.size - 1][:included]
        v += velocity_from_scope rabu_iterations[rabu_iterations.size - 2][:included]
        iteration_count += 2
      elsif rabu_iterations && rabu_iterations.size == 1
        v += velocity_from_scope rabu_iterations[rabu_iterations.size - 1][:included]
        iteration_count += 1
      end
      v / iteration_count
    end

    def completed_stories(stories)
      completed = 0
      stories.each {|s| completed += s[:estimate].to_i if s[:estimate] && s[:estimate].to_i}
      completed
    end

    def scope_remaining_after_and_added_during(iteration_start_time, iteration_end_time, pivotal_iterations)
      remaining = 0
      added = 0 
      pivotal_iterations.each do |pi|
        # skip stories already completed in earlier sprints
        next if pi[:started] && pi[:started] < iteration_start_time 
        # count all stories created before (or during) the sprint, but completed after iterations
        pi[:stories].each do |s|
          remaining += s[:estimate].to_i    if s[:created_at] && s[:estimate] && compare(s[:created_at], 'lte', iteration_end_time)   && compare(pi[:start], 'gte', iteration_end_time)
          added += s[:estimate].to_i if s[:created_at] && s[:estimate] &&compare(s[:created_at], 'gte', iteration_start_time) && compare(s[:created_at], 'lte', iteration_end_time)
        end
      end
      [["remaining scope", remaining], ["added scope", added]]
    end
    
    def scope(pi, pivotal_iterations)
      remaining_added = scope_remaining_after_and_added_during(pi[:start], pi[:finish], pivotal_iterations)
      [remaining_added[0], remaining_added[1], ["completed scope", completed_stories(pi[:stories])]]
    end

    # create scope for current iteration with
    #  - completed milestones
    #  - milestones remaining
    #  - 2-3 milestones out of scope for "what if " conversations
    def add_milestones_2_rabu(rabu, done_pivotal_iterations, backlog_pivotal_iterations)
        cm = milestones(done_pivotal_iterations)
        # remove the last unknown milestone.  that's completed scope
        cm.delete_at(cm.size - 1)
        fm = milestones(backlog_pivotal_iterations, false)
        # put 3 out of scope if there are enough milestones for "what if" scoping
        out_of_scope = []
        if fm.size > 3
          out_of_scope = fm[(fm.size - 3)..(fm.size - 1)]
          fm = fm[0..(fm.size - 4)]
        end
        # TODO get current iteration info
        started = Time.now
        length = 14
        velocity = 84
        current_iteration =
          {
            :started => started,
            :length => length,
            :velocity => velocity,
            :riskMultipliers => [1, 1.2, 1.4],
            :included => cm +fm,
            :excluded => out_of_scope
          }
      # put current_iteration at top of rabu iterations
      rabu[:iterations].insert(0, current_iteration)
      rabu
    end

    def milestones(done, zero_estimate = true)
      m = [['unnamed', 0]]
      done.each do |iterations|
        iterations[:stories].each do |s|
          m.last[1] += s[:estimate].to_i if s[:story_type] != 'release' && s[:estimate] && s[:estimate].to_i
          if s[:story_type] == 'release'
            m.last[0] = s[:name]
            m.last[1] = 0 if zero_estimate
            m << ['unnamed', 0]
          end
        end
      end
      m
    end
    
    def length_of_iteration_in_days(start,finish)
      Integer ((finish - start) / 60 / 60 / 24)
    end
    
    def rabu_time_format(time)
      return nil unless time and time.is_a? Time
      time.strftime("%d %b %Y")
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
    
end