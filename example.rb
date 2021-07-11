require "yaml"
require_relative "lib/drawght"

yaml = File.read("example.yaml")
data = YAML.load(yaml)

puts "Dataset", yaml
Dir.glob "*.in" do |file|
  template = File.read(file)
  drawght = Drawght.new(template)
  line = "-" * 78
  puts line
  puts drawght.parse_template("Template '#{file}' ({title})", data)
  puts line
  puts template
  puts line
  puts drawght.parse(data)
end
