#! /bin/env ruby -Ilib:test

# encoding: utf-8

module Commands
  def self.changelog
    require "yaml"

    @changelog ||= YAML.safe_load_file "#{__dir__}/CHANGELOG.yaml", permitted_classes: [Symbol, Date]
  end

  def self.release
    @release ||= Release.new **changelog.first
  end

  def self.test file = nil
    require "minitest/autorun"
    require "pry-byebug"
    require_relative "#{__dir__}/lib/drawght"

    filename_pattern = file || "#{__dir__}/test/*_test.rb"

    Dir.glob filename_pattern do |file|
      load file
    end
  end

  def self.versioning filename = nil
    require "erb"

    template = "#{__dir__}/lib/drawght/version.rb.erb"
    versioning = filename || template.sub(".erb", "")
    templating = File.read template
    renderer = ERB.new templating, trim_mode: '-'

    File.write versioning, renderer.result(release.instance_eval{ binding })
  end

  Release = Struct.new *changelog.first.keys.map(&:to_sym)
end

if __FILE__ == $PROGRAM_NAME
  command = ARGV.shift.to_sym
  Commands.send command, *ARGV if Commands.methods(false).include? command
end
