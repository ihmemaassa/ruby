require 'net/http'
require 'uri'
require 'io/console'

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

print "Provide auth key: " 
STDOUT.flush
token = STDIN.noecho(&:gets).chomp
puts
puts "Entered auth key: #{token[0..2]}#{'*' * (token.length - 6)}#{token[-3..-1]}"
token
puts

uri = URI.parse("https://api.testaustime.fi/users/@me/activity/data")
request = Net::HTTP::Get.new(uri)
request["Authorization"] = "Bearer #{token}"

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

source = response.body

lines = source.scan(/\{.*?\}/)
all_lines = []
lines.each do |line|
  all_lines << line
end

puts "You have #{all_lines.length} data records" 
puts
puts"    Options
    1 - Delete all
    2 - Delete selected
    3 - Save selected
    4 - Exit"
puts    
print "Please select: "
select = gets.chomp.to_i

def delete_request(token, lines_to_delete)
  regex = /(?<=\:)(\d{6})(?=\,)/

  id_list = []
  lines_to_delete.each do |line|
    matches = line.scan(regex)
    id_list += matches
  end
  
  id_list.each do |id|
    uri = URI.parse('https://api.testaustime.fi/activity/delete')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
  
    request = Net::HTTP::Delete.new(uri.request_uri)
    request['Authorization'] = "Bearer #{token}"
    request.body = id[0]
    response = http.request(request)
    if response.code == "200"
      puts "Data record deleted."
    else
      puts "Deletion failed."
    end
  end
end

def confirm_deletion
  loop do
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
end

case select
when 1 #delete all

  puts "Deletes #{all_lines.length} data records"
  if confirm_deletion
    delete_request(token, all_lines)
  else 
    puts "Deletion cancelled"
  end

when 2 # delete selected

  print "What do you want to delete? "
  delete_words = gets.chomp.split(",").map(&:strip)
  selected_lines = all_lines.select { |line| delete_words.any? { |word| line.include?(word) } }
  puts "Deletes #{selected_lines.length} data records"
  if confirm_deletion
    delete_request(token, selected_lines)
  else
    puts "Deletion cancelled"
  end

when 3 # save selected

  print "What do you want to save? "
  save_words = gets.chomp.split(",").map(&:strip)
  selected_lines = all_lines.reject { |line| save_words.any? { |word| line.include?(word) } }
  puts "Deletes #{selected_lines.length} data records"
  if confirm_deletion
    delete_request(token, selected_lines)
  else
    puts "Deletion cancelled"
  end  

when 4 # exit

else
  puts "Not a valid option." 
end
