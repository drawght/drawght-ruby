module Drawght
  require_relative "drawght/parser"

  def self.new(template)
    Drawght::Parser.new template
  end
end
