load 'pivotal_2_rabu.rb'
p2r = Pivotal2Rabu.new
user = ARGV[0]
pass = ARGV[1]
project = ARGV[2]
token = p2r.get_token user,pass
rabu = p2r.past_2_rabu(token, project)
p rabu.inspect
