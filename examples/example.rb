require "date"
require "yaml"
require_relative "lib/drawght"

yaml = File.read "example.yaml"
data = YAML.load yaml, permitted_classes: [Symbol,Date]

puts "Dataset", yaml
Dir.glob "*.in" do |file|
  template = File.read file
  drawght = Drawght.load_template template
  line = "-" * 78
  puts line
  puts template
  puts line
  puts drawght.compile(data)
end

template = "{name} v{version} ({release date}/{start-at})"
result = Drawght::Compiler.new(template).compile **{
  name: "Drawght",
  version: "0.1.0",
  "release date" => "2021-07-01",
  "start-at" => "2021-06-30",
}

puts result
