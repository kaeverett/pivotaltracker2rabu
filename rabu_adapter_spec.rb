require 'pivotal_2_rabu'

describe RabuAdapter, "#rabu parsing" do
  
  it " counts days per iteration" do
    p2r = Pivotal2Rabu.new 
    p2r.length_of_iteration_in_days(Time.now, Time.now).should == 0
    p2r.length_of_iteration_in_days(Time.now, Time.now + (60 * 60 * 24 * 2) ).should == 2
  end
  
  it "converts valid time" do
    p2r = Pivotal2Rabu.new 
    rt = p2r.rabu_time_format(Time.utc(2010, 'Aug', 24))
    rt.index('24').should == 0
    rt.index('Aug').should_not == -1    
  end
  
  days = (60 * 60 * 24)
  
  # COMPLETED STORIES from pivotal_adaptor.get_done
  # just show historical completion and scoping
  now = Time.now
  pivotal_iterations = [
                          { :number=>'29', 
                            :start=>now - (42 * days), 
                            :finish=>now - (28 * days),                            
                            :stories=>[
                              {:created_at=>now - (100 * days), :story_type=>'feature', :estimate=>'8', :url=>'http://29a'}, 
                              {:created_at=>now - (100 * days), :story_type=>'bug', :estimate=>'2', :url=>'http://29b'}
                            ] 
                          },
                          { :number=>'30', 
                            :start=>now - (28 * days), 
                            :finish=>now - (14 * days),                            
                            :stories=>[
                              {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :estimate=>'8', :story_type=>'feature', :url=>'http://30a'}, 
                              {:created_at=>now - (40 * days), :updated_at=>now - (15 * days), :estimate=>'2', :owned_by=>'Mack', :story_type=>'bug', :url=>'http://30b'},
                              {:created_at=>now - (27 * days), :updated_at=>now - (15 * days), :estimate=>'5', :owned_by=>'Ken', :story_type=>'Feature', :url=>'http://30c'}
                            ] 
                          },
                          { :number=>'31', 
                            :start=>now - (14 * days), 
                            :finish=>now,                            
                            :stories=>[
                              {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :estimate=>'8', :story_type=>'feature', :url=>'http://31a'}, 
                              {:created_at=>now - (15 * days), :updated_at=>now - (15 * days), :estimate=>'2', :owned_by=>'Mack', :story_type=>'bug', :url=>'http://31b'},
                              {:created_at=>now - (13 * days), :updated_at=>now - (15 * days), :estimate=>'5', :owned_by=>'Ken', :story_type=>'Feature', :url=>'http://31c'}
                            ] 
                          }                          
                        ]
        
  it "iterations 29 had x remaining" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (42 * days), Time.now - (28 * days), pivotal_iterations)
    scope[0][0].should == 'remaining scope'
    scope[0][1].should == 18  # 2 + 8 from sprint 30.   8 from sprint 31  
  end

  it "iterations 30 had x remaining" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (28 * days), Time.now - (14 * days), pivotal_iterations)
    scope[0][0].should == 'remaining scope'
    scope[0][1].should == 10 # 2 + 8 from sprint 31
  end

  it "iterations 31 had x remaining" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (14 * days), Time.now, pivotal_iterations)
    scope[0][0].should == 'remaining scope'
    scope[0][1].should == 0 # all scope completed in sprint 31    
  end  
  
  it "calculate_velocity" do
    pending "TBD"
  end
end
