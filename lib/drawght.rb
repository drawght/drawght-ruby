# encoding: utf-8
# frozen_string_literal: true

module Drawght
  require_relative "drawght/parser"
  require_relative "drawght/tracker"
  require_relative "drawght/compiler"
  require_relative "drawght/version"

  Release = Struct.new :version, :date, :summary, :changes

  def self.load_template(template)
    Compiler.new template
  end

  def self.compile(template, data)
    load_template(template).compile data
  end
end
