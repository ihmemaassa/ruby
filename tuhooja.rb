require 'net/http'
require 'uri'
require 'io/console'

# banneri luotu ohjelmalla https://patorjk.com/software/taag/ fontti 'Big' 
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

    	  T I E T U E T U H O O J A

TT
puts banner

print "Anna tunnistautumistunnus: " 
STDOUT.flush
token = STDIN.noecho(&:gets).chomp
puts
puts "Tunnistautumistunnuksesi: #{token[0..2]}#{'*' * (token.length - 6)}#{token[-3..-1]}"
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

puts "Sinulla on #{all_lines.length} tietuetta" 
puts
puts"    Valikko
    1 - Poista kaikki
    2 - Poista valitut
    3 - Säästä valitut
    4 - Poistu"
puts    
print "Valitse: "
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
      puts "Tietue poistettu."
    else
      puts "Poistaminen epäonnistui."
    end
  end
end

def confirm_deletion
  loop do
    print "Poista tietue? (k/e): "
    response = gets.chomp.downcase
    case response
    when 'k'
      return true
    when 'e'
      return false
    else
      puts "Ei kelvollinen valinta, valitse 'k' tai 'e'."
    end
  end
end

case select
when 1 #delete all

  puts "Poistaa #{all_lines.length} tietuetta"
  if confirm_deletion
    delete_request(token, all_lines)
  else 
    puts "Poistaminen peruttu"
  end

when 2 # delete selected

  print "Mitä haluat poistaa? "
  delete_words = gets.chomp.split(",").map(&:strip)
  selected_lines = all_lines.select { |line| delete_words.any? { |word| line.include?(word) } }
  puts "Poistaa #{selected_lines.length} tietuetta"
  if confirm_deletion
    delete_request(token, selected_lines)
  else
    puts "Poistaminen peruttu"
  end

when 3 # save selected

  print "Mitä haluat säästää? "
  save_words = gets.chomp.split(",").map(&:strip)
  selected_lines = all_lines.reject { |line| save_words.any? { |word| line.include?(word) } }
  puts "Poistaa #{selected_lines.length} tietuetta"
  if confirm_deletion
    delete_request(token, selected_lines)
  else
    puts "Poistaminen peruttu"
  end  

when 4 # exit

else
  puts "Ei kelvollinen valinta." 
end
