#! /usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require "date"
require "erb"
require "pry-byebug" if ENV["DEBUG"]&.match? /\A(?:1|yes|true)\z/i
require "yaml"

require_relative "#{__dir__}/lib/drawght"

module CommandRunner
  RUNNABLES = %i[test versioning].freeze

  def self.test file = nil
    require "minitest/autorun"

    filename_pattern = file || "#{__dir__}/test/*_test.rb"

    Dir.glob filename_pattern do |pathname|
      require pathname
    end
  end

  def self.versioning filename = nil
    template = "#{__dir__}/lib/drawght/version.rb.erb"
    versioning = filename || template.sub(".erb", '')
    templating = File.read template
    renderer = ERB.new templating, trim_mode: '-'

    File.write versioning, renderer.result_with_hash(release.to_h)
  end

  private_class_method

  def self.changelog
    @changelog ||= YAML.safe_load_file "#{__dir__}/CHANGELOG.yaml", permitted_classes: [Date]
  end

  def self.release
    @release ||= Drawght::Release.new **changelog.first
  end
end

if __FILE__ == $PROGRAM_NAME
  command = ARGV.shift&.to_sym

  if CommandRunner::RUNNABLES.include? command
    CommandRunner.send command, *ARGV
  else
    warn "Invalid command: '#{command}'. Available commands: #{CommandRunner::RUNNABLES.join ', '}"
    exit 1
  end
end
