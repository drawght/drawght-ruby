# encoding: utf-8
# frozen_string_literal: true

module Drawght
  module Parser
    TOKENS = [
      ATTRIBUTE = '.',
      ITEM = '#',
      SEQUENCER = ':',
    ]

    STRAIGHTLY_PATTERN = Regexp.new "\\#{ATTRIBUTE}|\\#{ITEM}"
    SEQUENTIAL_PATTERN = Regexp.new "\\#{SEQUENCER}"

    using ArrayExtensions

    def pathkeys_from string
      path = case string
             when STRAIGHTLY_PATTERN then
               pathkeys_for_attribute string
             when SEQUENTIAL_PATTERN then
               pathkeys_for_collection string
             else
               [string]
             end

      path.flatten
    end

    def placeholders_from string
      return [] unless string =~ PLACEHOLDERS_PATTERN

      string.scan(PLACEHOLDERS_PATTERN).flatten
    end

    def mapping_placeholders_from string
      clear_placeholder_mappings!

      placeholders_from(string).map do |placeholder|
        if placeholder =~ SEQUENTIAL_PATTERN
          placeholder.scan %r/^(.*)#{SEQUENCER}(.*)$/ do |pathkeys, attribute|
            (sequential_placeholders[pathkeys] ||= {}).update placeholder => attribute
          end
        else
          straightly_placeholders.add placeholder
        end

        placeholder
      end
    end

    def straightly_placeholders
      @straightly_placeholders ||= []
    end

    def sequential_placeholders
      @sequential_placeholders ||= {}
    end

    private

    def pathkeys_for_attribute placeholder
      placeholder.split(STRAIGHTLY_PATTERN).map do |item|
        value = item.to_s
        if value =~ SEQUENTIAL_PATTERN
          pathkeys_for_collection item
        else
          value =~ /^\d/ ? item.to_i - 1 : item unless value.empty?
        end
      end.compact
    end

    def pathkeys_for_collection placeholder
      placeholder
        .gsub(SEQUENCER, "#{SEQUENCER}&#{SEQUENCER}")
        .split(SEQUENTIAL_PATTERN)
        .map do |item|
          if item.to_s =~ STRAIGHTLY_PATTERN
            pathkeys_for_attribute item
          else
            item
          end
        end
    end

    def clear_placeholder_mappings!
      straightly_placeholders.clear && sequential_placeholders.clear
    end
  end
end
