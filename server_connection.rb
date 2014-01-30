# Logs into a Rails app with one command'
#
# $ echo "You'll need the APP_ID of a Rails app, such as 4521"
# APP_ID=4521
# $ ruby server_connection:new $APP_ID

# required to use the Open3 standard library
require "open3"

# ID of the Rails App
app_id    = ARGV[0].to_s

# Will be assignd to the block created by knife
block_id  = ""

# ID of the server, needed to get the public IP
node_id   = ""

# Used to connect to the approptiate directory
username  = `whoami`.chomp

# Gets password, stored in a text file
# WARNING:  Not very secure!
password  = File.read("/Users/" + username + "/.chef/password.txt").chomp
public_ip = ""

# command line script for generating the knife block
generate_block_and_set_block_id  = "cd /Users/" + username + "/.chef;"
generate_block_and_set_block_id << "knife block prod-customer;"
generate_block_and_set_block_id << "knife ninefold-internal -a " + app_id + " -g;"

# $ knife ninefold internal -a $APP_ID -g
Open3.popen3(generate_block_and_set_block_id) do |stdin, stdout, _, _|
  stdin.puts password
  stdin.close

  stdout.each_line do |line|
    block_id = line.split(" ")[-1].split("\e[m")[0]
    puts line
  end
end

# command line sript to get node_id, which we'll call $NODE_ID
set_node_id  = "cd /Users/" + username + "/.chef;"
set_node_id << "knife block " + block_id + ";"
set_node_id << "knife node list;"

# $ knife node list
Open3.popen3(set_node_id) do |_, stdout, _, _|
  stdout.each_line do |line|
    node_id = line.chomp
    puts line
  end
end

# command line script to get the public ip, which we'll call $PUBLIC_IP
set_public_ip  = "cd /Users/" + username + "/.chef;"
set_public_ip << "knife node show " + node_id + " -fj | grep nat"

# $ knife node show $NODE_ID -Fj | grep nat
Open3.popen3(set_public_ip) do |_, stdout, _, _|
  stdout.each_line do |line|
    public_ip = line.split("\"")[-2]
    puts line
  end
end

# command line script to SSH into box
server_sign_in  = "cd /Users/" + username + "/.chef/" + block_id + ";"
server_sign_in << "ssh -i id_rsa user@" + public_ip + ";"

# $ ssh -i id_rsa user@$PUBLIC_IP
system(server_sign_in)
