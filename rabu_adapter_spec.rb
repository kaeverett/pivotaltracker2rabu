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
        
  it "iterations 29 had 18 remaining" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (42 * days), Time.now - (28 * days), pivotal_iterations)
    scope[0][0].should == 'remaining scope'
    scope[0][1].should == 18  # 2 + 8 from sprint 30.   8 from sprint 31  
  end

  it "iterations 30 had 10 remaining" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (28 * days), Time.now - (14 * days), pivotal_iterations)
    scope[0][0].should == 'remaining scope'
    scope[0][1].should == 10 # 2 + 8 from sprint 31
  end

  it "iterations 31 had 0 remaining" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (14 * days), Time.now, pivotal_iterations)
    scope[0][0].should == 'remaining scope'
    scope[0][1].should == 0 # all scope completed in sprint 31    
  end  

  it "iterations 29  added 2" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (42 * days), Time.now - (28 * days), pivotal_iterations)
    scope[1][0].should == 'added scope'
    scope[1][1].should == 2 # all scope completed in sprint 31
  end

  it "iterations 30 added 7" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (28 * days), Time.now - (14 * days), pivotal_iterations)
    scope[1][0].should == 'added scope'
    scope[1][1].should == 7 # 2 + 8 from sprint 31
  end

  it "iterations 31 added 7" do
    p2r = Pivotal2Rabu.new
    scope = p2r.scope_remaining_after_and_added_during(Time.now - (14 * days), Time.now, pivotal_iterations)
    scope[1][0].should == 'added scope'
    scope[1][1].should == 5 # 2 + 8 from sprint 31
  end

  it "iterations 29 completed 10" do
    p2r = Pivotal2Rabu.new
    scope = p2r.completed_stories(pivotal_iterations[0][:stories])
    scope.should == 10
  end

  it "scope pulls together remaining, added and completed" do
    p2r = Pivotal2Rabu.new
    s = p2r.scope(pivotal_iterations[0], pivotal_iterations)
    s[0][0].should == 'remaining scope'
    s[0][1].should == 18  # 2 + 8 from sprint 30.   8 from sprint 31  
    s[1][0].should == 'added scope'
    s[1][1].should == 2 # all scope completed in sprint 31
    s[2][0].should == 'completed scope'
    s[2][1].should == 10
  end

  it "calculate_velocity when there is only 1 iteration" do
    p2r = Pivotal2Rabu.new
    p2r.calculate_velocity([['scope remaining', 10], ['scope added', 5], ['scope completed', 10]], []).should == 10
  end

  it "calculates velocity by average of 2 when there is 2 iterations" do
    rabu_2_iterations = [
      { :included => [['scope remaining', 20], ['scope added', 5], ['scope completed', 10]] }
    ]
    p2r = Pivotal2Rabu.new
    p2r.calculate_velocity([['scope remaining', 15], ['scope added', 5], ['scope completed', 8]], rabu_2_iterations).should == 9
  end

  it "calculates velocity by average of 3 when there is 3 iterations" do
    rabu_3_iterations = [
      { :included => [['scope remaining', 20], ['scope added', 5], ['scope completed', 10]] },
      { :included => [['scope remaining', 20], ['scope added', 5], ['scope completed', 11]] }
    ]
    p2r = Pivotal2Rabu.new
    p2r.calculate_velocity([['scope remaining', 15], ['scope added', 5], ['scope completed', 8]], rabu_3_iterations).should == 9
  end

  it "calculates velocity by average of 3 when there is 4 iterations" do
    rabu_4_iterations = [
      { :included => [['scope remaining', 20], ['scope added', 5], ['scope completed', 20]] },
      { :included => [['scope remaining', 20], ['scope added', 5], ['scope completed', 10]] },
      { :included => [['scope remaining', 20], ['scope added', 5], ['scope completed', 11]] }
    ]
    p2r = Pivotal2Rabu.new
    p2r.calculate_velocity([['scope remaining', 15], ['scope added', 5], ['scope completed', 8]], rabu_4_iterations).should == 9
  end

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
                                {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :name => 'm1', :story_type=>'release', :url=>'http://30b'},
                              {:created_at=>now - (40 * days), :updated_at=>now - (15 * days), :estimate=>'2', :owned_by=>'Mack', :story_type=>'bug', :url=>'http://30c'},
                              {:created_at=>now - (27 * days), :updated_at=>now - (15 * days), :estimate=>'5', :owned_by=>'Ken', :story_type=>'Feature', :url=>'http://30d'}
                            ]
                          },
                          { :number=>'31',
                            :start=>now - (14 * days),
                            :finish=>now,
                            :stories=>[
                              {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :estimate=>'8', :story_type=>'feature', :url=>'http://31a'},
                              {:created_at=>now - (15 * days), :updated_at=>now - (15 * days), :estimate=>'2', :owned_by=>'Mack', :story_type=>'bug', :url=>'http://31b'},
                              {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :name => 'm2', :story_type=>'release', :url=>'http://30b'},
                              {:created_at=>now - (13 * days), :updated_at=>now - (15 * days), :estimate=>'5', :owned_by=>'Ken', :story_type=>'Feature', :url=>'http://31c'}
                            ]
                          }
                        ]

  it "can tally completed milestones" do
    p2r = Pivotal2Rabu.new
    completed_scope = p2r.milestones(pivotal_iterations)
    completed_scope[0][0].should == 'm1'
    completed_scope[0][1].should == 0
    completed_scope[1][0].should == 'm2'
    completed_scope[1][1].should == 0
    completed_scope[2][0].should == 'unnamed'
    completed_scope[2][1].should == 5
    completed_scope.should == [['m1', 0],['m2', 0], ['unnamed', 5]]
  end

  it "can tally future milestones" do
    p2r = Pivotal2Rabu.new
    completed_scope = p2r.milestones(pivotal_iterations, false)
    completed_scope[0][0].should == 'm1'
    completed_scope[0][1].should == 18
    completed_scope[1][0].should == 'm2'
    completed_scope[1][1].should == 17
    completed_scope[2][0].should == 'unnamed'
    completed_scope[2][1].should == 5
    completed_scope.should == [['m1', 18],['m2', 17], ['unnamed', 5]]
  end

  it "can tally all milestones into rabu format" do
    rabu =
        { :updated=>"23 Aug 2011", :name=>"pivotal project", :iterations=>
           [{:velocity=>38, :length=>14, :included=>[["remaining scope", 20], ["added scope", 11], ["completed scope", 44]], :started=>"01 Aug 2011"},
            {:velocity=>29, :length=>14, :included=>[["remaining scope", 35], ["added scope", 39], ["completed scope", 89]], :started=>"18 Jul 2011"}]
        }
    p2r = Pivotal2Rabu.new
    rabu = p2r.add_milestones_2_rabu(rabu, pivotal_iterations, pivotal_iterations)
    rabu[:iterations].first[:included].should == [['m1', 0],['m2', 0], ['m1', 18],['m2', 17], ['unnamed', 5]]
    rabu[:iterations].first[:excluded].should == []
  end

  done = [
                          { :number=>'26',
                            :start=>now - (42 * days),
                            :finish=>now - (28 * days),
                            :stories=>[
                              {:created_at=>now - (100 * days), :story_type=>'feature', :estimate=>'8', :url=>'http://29a'},
                              {:created_at=>now - (100 * days), :story_type=>'bug', :estimate=>'2', :url=>'http://29b'}
                            ]
                          },
                          { :number=>'27',
                            :start=>now - (28 * days),
                            :finish=>now - (14 * days),
                            :stories=>[
                                {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :estimate=>'8', :story_type=>'feature', :url=>'http://30a'},
                                {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :name => 'm1a', :story_type=>'release', :url=>'http://30b'},
                              {:created_at=>now - (40 * days), :updated_at=>now - (15 * days), :estimate=>'2', :owned_by=>'Mack', :story_type=>'bug', :url=>'http://30c'},
                              {:created_at=>now - (27 * days), :updated_at=>now - (15 * days), :estimate=>'5', :owned_by=>'Ken', :story_type=>'Feature', :url=>'http://30d'}
                            ]
                          },
                          { :number=>'28',
                            :start=>now - (14 * days),
                            :finish=>now,
                            :stories=>[
                              {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :estimate=>'8', :story_type=>'feature', :url=>'http://31a'},
                              {:created_at=>now - (15 * days), :updated_at=>now - (15 * days), :estimate=>'2', :owned_by=>'Mack', :story_type=>'bug', :url=>'http://31b'},
                              {:created_at=>now - (100 * days), :updated_at=>now - (15 * days), :name => 'm2a', :story_type=>'release', :url=>'http://30b'},
                              {:created_at=>now - (13 * days), :updated_at=>now - (15 * days), :estimate=>'5', :owned_by=>'Ken', :story_type=>'Feature', :url=>'http://31c'}
                            ]
                          }
                        ]



  it "splits milestones between included/excluded if there are more than 3" do
    pivotal_iterations << { :number=>'32',
                            :start=>now - (42 * days),
                            :finish=>now - (28 * days),
                            :stories=>[
                              {:created_at=>now - (100 * days), :story_type=>'release', :name => 'm3', :url=>'http://29a'},
                              {:created_at=>now - (100 * days), :story_type=>'bug', :estimate=>'2', :url=>'http://29b'}
                            ]
                          }
    rabu =
        { :updated=>"23 Aug 2011", :name=>"pivotal project", :iterations=>
           [{:velocity=>38, :length=>14, :included=>[["remaining scope", 20], ["added scope", 11], ["completed scope", 44]], :started=>"01 Aug 2011"},
            {:velocity=>29, :length=>14, :included=>[["remaining scope", 35], ["added scope", 39], ["completed scope", 89]], :started=>"18 Jul 2011"}]
        }
    p2r = Pivotal2Rabu.new
    rabu = p2r.add_milestones_2_rabu(rabu, done, pivotal_iterations)
    rabu[:iterations].first[:included].should == [["m1a", 0], ["m2a", 0], ["m1", 18]]
    rabu[:iterations].first[:excluded].should == [["m2", 17], ["m3", 5], ["unnamed", 2]]
  end
end
