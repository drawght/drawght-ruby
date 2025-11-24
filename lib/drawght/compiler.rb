# encoding: utf-8
# frozen_string_literal: true

module Drawght

class Compiler
  using Drawght::Extensions

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

      partial = line.dup

      convert_variables_from partial

      convert_attributes_from partial

      convert_listing_from partial

      partial
    end

    result.replace lines.join
  end

  def convert_variables_from template
    if (variables = placeholders_for_variables_from template).any?
      current_result = variables.reduce template do |partial, key|
        value = dataset.fetch key
        [value].flatten.map{ |item| replace_placeholders partial.dup, key, item }.join
      end

      template.replace current_result
    end
  end

  # Get variables placeholders, like `{}`
  def placeholders_for_variables_from template
    sentences = sentences_for template
    sentences.reject! { |key| (key.match? ATTRIBUTES_PATTERN) || (key.match? QUERY) }
    sentences
  end

  def sentences_for template
    template.scan(PLACEHOLDERS_PATTERN).flatten
  end

  def replace_placeholders template, key, value
    template.gsub! placeholder_key(key), value.to_s
  end

  def placeholder_key key
    "#{PREFIX}#{key}#{SUFFIX}"
  end

  def convert_attributes_from template
    if (keypaths = placeholders_for_attributes_from template).any?
      keypaths.map do |keypath|
        placeholder = []

        keypath.map! do |attribute|
          if attribute.match? /\d+/
            placeholder.last << ITEM << attribute.dup
            attribute.to_i - 1
          else
            placeholder << attribute.dup
            attribute
          end
        end

        value = dataset.dig *keypath

        next template if value.nil?

        replace_placeholders template, placeholder.join(ATTRIBUTE), value
      end
    end
  end

  def placeholders_for_attributes_from line
    placeholders_for line, ATTRIBUTES_PATTERN
  end

  def placeholders_for template, delimiter
    sentences_for(template)
      .map{ |placeholder| placeholder.split delimiter }
      .select{ |items| items.size > 1 }
      .uniq
  end

  def convert_listing_from template
    if (keypaths = placeholders_for_listing_from template).any?
      keypaths
        .group_by(&:first)
        .map do |list_key, path_keys|
          attributes = placeholders_for_attributes_from(placeholder_key list_key).flatten
          list = attributes.any? ? dataset.dig(*attributes) : dataset.dig(*list_key)

          next [template] unless list.is_a? Array

          result = String.new # Why '' is frozen?
          list.each do |item|
            result << template.dup
            path_keys.each do |_, key|
              attributes = placeholders_for_attributes_from(placeholder_key key).flatten
              value = attributes.any? ? item.dig(*attributes) : item[key]
              replace_placeholders result, "#{list_key}#{QUERY}#{key}", value
            end
          end

          template.replace result
        end
    end
  end

  def placeholders_for_listing_from line
    placeholders_for line, QUERY
  end
end

end
