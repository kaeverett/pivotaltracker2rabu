require 'pivotal_2_rabu'

describe PivotalAdapter, "#pivotal parsing" do
  it "parses pivotal valid timestamp format" do
    p2r = Pivotal2Rabu.new
    t = p2r.get_time '2010/07/28 15:14:25 PDT'
    t.should == Time.mktime(2010, 07, 28, 15, 14, 25)
  end

  it "does not puke on invalid timestamp format" do
    p2r = Pivotal2Rabu.new
    t = p2r.get_time '2010/0728 15:14:25 PDT'
    t.should == nil
  end

  valid_iterations = " <?xml version='1.0' encoding='UTF-8'?>
                      <iterations type='array'>
                        <iteration>
                          <id type='integer'>29</id>
                          <number type='integer'>29</number>
                          <start type='datetime'>2011/08/15 00:00:00 PDT</start>
                          <finish type='datetime'>2011/08/29 00:00:00 PDT</finish>
                          <team_strength type='float'>1</team_strength>
                          <stories type='array'>
                            <story>
                              <id type='integer'>12178321</id>
                              <project_id type='integer'>1022</project_id>
                              <story_type>feature</story_type>
                              <url>http://www.pivotaltracker.com/story/show/121783</url>
                              <estimate type='integer'>8</estimate>
                              <current_state>unstarted</current_state>
                              <description>- description</description>
                              <name>appraisal score transform (MVC) results</name>
                              <requested_by>ken</requested_by>
                              <created_at type='datetime'>2011/04/11 16:33:44 PDT</created_at>
                              <updated_at type='datetime'>2011/06/09 00:01:48 PDT</updated_at>
                              <labels>appraisal</labels>
                              <notes type='array'>
                                <note>
                                  <id type='integer'>7001875</id>
                                  <text>delayed until we hear from customers. </text>
                                  <author>ken</author>
                                  <noted_at type='datetime'>2011/05/13 15:08:52 PDT</noted_at>
                                </note>
                              </notes>
                            </story>
                            <story>
                              <id type='integer'>13395673</id>
                              <project_id type='integer'>102222</project_id>
                              <story_type>bug</story_type>
                              <url>http://www.pivotaltracker.com/story/show/13395</url>
                              <owned_by>Mack</owned_by>
                              <current_state>unstarted</current_state>
                              <name>another story ..</name>
                              <description>*really* dislike the ..</description>
                              <requested_by>Mack</requested_by>
                              <created_at type='datetime'>2011/05/13 17:13:23 PDT</created_at>
                              <updated_at type='datetime'>2011/06/09 00:02:18 PDT</updated_at>
                              <labels>process,refactor</labels>
                            </story>
                          </stories>
                        </iteration>
                      </iterations>"
                      
  p2r = Pivotal2Rabu.new
  doc = Hpricot(valid_iterations).at('iterations') 
  iterations = p2r.parse_iterations(doc)
  
  it "parses iterations attributes" do
    iterations.size.should == 1    
    iterations.first[:number].should == '29'
    iterations.first[:start].should ==  Time.mktime(2011, 8, 15, 0, 0, 0) 
    iterations.first[:finish].should == Time.mktime(2011, 8, 29, 0, 0, 0) 
  end
  
  it "parses the first story" do
    story = iterations.first[:stories].first
    story[:story_type].should == 'feature'
    story[:url].should == 'http://www.pivotaltracker.com/story/show/121783'
    story[:created_at].should == Time.mktime(2011, 4, 11, 16, 33, 44) 
    story[:updated_at].should == Time.mktime(2011, 6, 9, 00, 01, 48) 
    story[:estimate].should == '8'
    story[:owned_by].should == nil
  end
  
  it "parses the second story" do
    story = iterations.first[:stories].last
    story[:story_type].should == 'bug'
    story[:url].should == 'http://www.pivotaltracker.com/story/show/13395'
    story[:created_at].should == Time.mktime(2011, 5, 13, 17, 13, 23) 
    story[:updated_at].should == Time.mktime(2011, 6, 9, 0, 2, 18) 
    story[:estimate].should == nil
    story[:owned_by].should == 'Mack'
  end

  it "parses the name" do
    story = iterations.first[:stories].last
    story[:name].should_not == nil
  end

end
  