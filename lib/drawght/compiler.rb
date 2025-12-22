# encoding: utf-8
# frozen_string_literal: true

module Drawght

class Compiler
  using AllExtensions

  include Parser
  include Tracker

  attr_reader :template, :dataset, :result

  def initialize template, dataset = nil
    @template = template
    @result = template.dup
    @dataset = dataset.deep_stringify_keys! if dataset
  end

  def compile dataset
    @dataset ||= dataset.deep_stringify_keys!
    compile!
  end

  def compile!
    convert
    result
  end

  private

  def convert
    lines = template.lines.map do |line|
      next line unless line.match? PLACEHOLDERS_PATTERN

      mapping_placeholders_from line

      newline = convert_structural_placeholders_from line

      convert_sequential_placeholders_from newline
    end

    result.replace lines.join
  end

  def convert_structural_placeholders_from string
    structural_placeholders.reduce string.dup do |template, holding|
      matter = pathing dataset, *pathkeys_from(holding)

      converted = [matter].flatten.map do |value|
        template.dup.gsub! holding.to_placeholder, value.to_s
      end

      template.replace converted.join
    end
  end

  def convert_sequential_placeholders_from string
    sequential_placeholders.reduce string.dup do |template, (attribute, mappings)|
      matter = pathing dataset, *pathkeys_from(attribute)

      converted = matter.map do |values|
        mappings.inject template.dup do |partial, (holding, key)|
          value = pathing(values, *pathkeys_from(key)) || key
          partial.dup.gsub! holding.to_placeholder, value.to_s
        end
      end

      template.replace converted.join
    end
  end
end

end
