# encoding: utf-8
# frozen_string_literal: true

module Drawght

module HashExtensions
  refine Hash do
    def deep_stringify_keys!
      transform_keys! do |key|
        case value = fetch(key)
        when Hash then value.deep_stringify_keys!
        when Array then
          value.map! do |item|
            (item.is_a? Hash) ? item.deep_stringify_keys! : item
          end
        end

        key.to_s
      end

      self
    end
  end
end

class Compiler
  using HashExtensions

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
      next line unless has_placeholders? line

      mapping_placeholders_from line

      newline = convert_structural_placeholders_from line

      convert_sequential_placeholders_from newline
    end

    result.replace lines.join
  end

  def convert_structural_placeholders_from string
    structural_placeholders.reduce string.dup do |template, expression|
      matter = pathing dataset, *pathkeys_from(expression)

      converted = [matter].flatten.map do |value|
        template.dup.gsub! pathize(expression), value.to_s
      end

      template.replace converted.join
    end
  end

  def convert_sequential_placeholders_from string
    sequential_placeholders.reduce string.dup do |template, (attribute, mappings)|
      matter = pathing dataset, *pathkeys_from(attribute)

      converted = matter.map do |values|
        mappings.inject template.dup do |partial, (expression, key)|
          value = pathing(values, *pathkeys_from(key)) || key
          partial.dup.gsub! pathize(expression), value.to_s
        end
      end

      template.replace converted.join
    end
  end
end

end
