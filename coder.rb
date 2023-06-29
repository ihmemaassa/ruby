class Coder
  attr_accessor :name 
  def issue(skill)
    puts "#{@name} has skill issue with #{skill}"
  end
  def likes(skill)
    puts "#{@name} kind of likes #{skill}"
  end
end
