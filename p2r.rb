load 'pivotal_2_rabu.rb'
p2r = Pivotal2Rabu.new
user = ARGV[0]
pass = ARGV[1]
project = ARGV[2]
$current_velocity = ARGV[3]
token = p2r.get_token user,pass
puts p2r.convert(token, project)
