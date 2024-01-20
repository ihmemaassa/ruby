require 'net/http'
require 'uri'
require 'io/console'
require 'json'

# banner created with https://patorjk.com/software/taag/ font 'Big' 
banner = <<TT 
  _______        _                ####### 
 |__   __|      | |             ##   #   ##
    | | ___  ___| |_ __ _ _   ##___  #     ##
    | |/ _ \\/ __| __/ _` | | | / __| #  #    #
    | |  __/\\__ \\ || (_| | |_| \\__ \\ # #      #
    |_|\\___||___/\\__\\__,_|\\__,_|___/ ##       #
    | | (_)                 #                 #
    | |_ _ _ __ ___   ___    #               #
    |  _| | '_ ` _ \\ / _ \\    ##           ##
    | |_| | | | | | |  __/      ##       ##
     \\__|_|_| |_| |_|\\___|        #######

    	D A T A  D E S T R O Y E R

TT
puts banner

URI_auth = 'https://api.testaustime.fi/auth/login'
URI_sec = 'https://api.testaustime.fi/auth/securedaccess'
URI_data = 'https://api.testaustime.fi/users/@me/activity/data'
@URI_del = 'https://api.testaustime.fi/activity/delete'

def get_credentials
  print "Provide your username: "
  @user = gets.chomp
  print "and password: "
  @pw = STDIN.noecho(&:gets).chomp
  puts
  @creds = JSON.dump({ "username" => @user, "password" => @pw })
  puts
end

def make_http_request(url, http_req_type, headers={}, body=nil)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP.const_get(http_req_type).new(uri)
  headers.each { |key, value| request[key] = value }
  request.body = body if body
  @response = http.request(request)
  if @response.code != "200"
    abort("Something went wrong, try again")
  end
end

def get_token(type)
  source = @response.body
  match = source.match(/[a-zA-Z0-9]{32}/)
  token = match[0].to_s
  puts "Your #{type} token: #{token[0..2]}#{'*' * (token.length - 6)}#{token[-3..-1]}"
  return token
end

def response_data
  source = @response.body.force_encoding('UTF-8').downcase #remove .downcase for case sensitive search 1/2
  lines = source.scan(/\{.*?\}/)
  @all_lines = []
  lines.each do |line|
    @all_lines << line
  end
end

def selected_lines(action)
  print "What do you want to #{action}? "
  words = gets.chomp.downcase.split(",").map(&:strip) # remove .downcase for case sensitive search 2/2
  selected_lines = @all_lines.public_send(action == 'save' ? :reject : :select) { |line| words.any? { |word| line.include?(word) } }
  puts "Deletes #{selected_lines.length} data records"
  if confirm_deletion
    delete_request(@token, selected_lines)
  else
    puts "Deletion cancelled"
  end
end

def timer
  59-((Time.now.to_i-@req_time.to_i)/60)
end

def print_menu
  puts
  puts "You have #{@all_lines.length} data records" 
  puts
  puts"    Options
      1 - Delete all
      2 - Delete selected
      3 - Save selected
      4 - Renew security token #{ timer <=0 ? "(expired)" : "(#{timer} min remaining)" }
      5 - Exit"
  puts
  print "Please select: "
  @select = gets.chomp.to_i
end

def delete_request(sec_token, lines_to_delete)
  regex = /(?<=\"id":)(\d*)(?=\,)/

  id_list = []
  lines_to_delete.each do |line|
    matches = line.scan(regex)
    id_list += matches
  end
  
  id_list.each do |id|
    header_del = { "Authorization" => "Bearer #{@sec_token}" }
    body_del = id[0]
    make_http_request(@URI_del,'Delete', header_del, body_del)
    if @response.code == "200"
      puts "Data record deleted."
    else
      puts "Deletion failed."
    end
  end
end

def confirm_deletion
  print "Delete data? (y/n): "
  response = gets.chomp.downcase
  case response
  when 'y'
    return true
  when 'n'
    return false
  else
    puts "Invalid input. Please enter 'y' or 'n'."
  end
end

get_credentials

@header_json = { "Content-Type" => "application/json" }
@body_creds = @creds
make_http_request(URI_auth, 'Post', @header_json, @body_creds)
@auth_token = get_token('authentication')

make_http_request(URI_sec, 'Post', @header_json, @body_creds)
@sec_token = get_token('security')
@req_time = Time.now

@header_data = { "Authorization" => "Bearer #{@auth_token}" }
loop do make_http_request(URI_data,'Get',@header_data)

response_data

print_menu

case @select
when 1 #delete all

  puts "Deletes #{@all_lines.length} data records"
  if confirm_deletion
    delete_request(@sec_token, @all_lines)
  else 
    puts "Deletion cancelled"
  end

when 2 # delete selected
  selected_lines('delete')
when 3 # save selected
  selected_lines('save')
when 4 # renew sec token
  make_http_request(URI_sec, 'Post', @header_json, @body_creds)
  @sec_token = get_token('security')  
  @req_time = Time.now
when 5 #exit
  break
else
  puts "Not a valid option." 
end
end
