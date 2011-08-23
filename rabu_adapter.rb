module RabuAdapter
    def convert_2_rabu(pivotal_iterations)
      rabu = {}
      rabu[:name] = 'pivotal project'
      rabu[:updated] = rabu_time_format Time.now
      rabu[:iterations] = []
      pivotal_iterations.each do |pi|
        length = length_of_iteration_in_days(pi[:start], pi[:finish])
        rabu[:iterations] << {
              :started => rabu_time_format(pi[:start]), 
              :length => length,
              :included => scope_remaining_after_and_added_during(pi[:start], pi[:finish], pivotal_iterations),
              :velocity => calculate_velocity(pi[:started], length, rabu[:iterations])
        }
      end
      rabu[:iterations] = rabu[:iterations].reverse        
      rabu
    end
    
    # count amount (completed - added) avg over 3 sprints
    def calculate_velocity(current_iteration_start, length, rabu_iterations)
      return 0
      v = 0
      p current_iteration_start, length, rabu_iterations
      return 0 unless rabu_iterations[:iterations]
      rabu_iterations[:iterations].each do |it|
        # TODO find completed/added
        # scope to current + 2 prior sprints
        completed = 0
        added = 0
        v += completed - added
      end
      v = v / 3
    end
    
    def scope_remaining_after_and_added_during(iteration_start_time, iteration_end_time, pivotal_iterations)
      remaining = 0
      added = 0 
      pivotal_iterations.each do |pi|
        # skip stories already completed in earlier sprints
        next if pi[:started] && pi[:started] < iteration_start_time 
        # count all stories created before (or during) the sprint, but completed after iterations
        pi[:stories].each do |s|
          remaining += s[:estimate].to_i    if s[:created_at] && compare(s[:created_at], 'lte', iteration_end_time) && s[:estimate]  && compare(pi[:start], 'gte', iteration_end_time)
          added += s[:estimate].to_i if s[:created_at] && compare(s[:created_at], 'gte', iteration_start_time) && compare(s[:created_at], 'gt', iteration_end_time) && s[:estimate]
        end
      end
      [["remaining scope", remaining], ["added scope", added]]
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