# encoding: utf-8
# frozen_string_literal: true

module Drawght
  module Parser
    def path_keys_from placeholder
      path = case placeholder
             when ATTRIBUTES_PATTERN then
               path_keys_for_attribute placeholder
             when QUERY_PATTERN then
               path_keys_for_query placeholder
             else
               [placeholder]
             end

      path.flatten
    end

    def placeholders_from string
      return [] unless string =~ PLACEHOLDERS_PATTERN

      string.scan(PLACEHOLDERS_PATTERN).flatten
    end

    private

    def path_keys_for_attribute placeholder
      placeholder.split(ATTRIBUTES_PATTERN).map do |item|
        if item.to_s =~ QUERY_PATTERN
          path_keys_for_query item
        else
          item.to_s =~ /^\d/ ? item.to_i - 1 : item unless item.to_s.empty?
        end
      end.compact
    end

    def path_keys_for_query placeholder
      placeholder.gsub(QUERY, "#{QUERY}&#{QUERY}").split(QUERY_PATTERN).map do |item|
        if item.to_s =~ ATTRIBUTES_PATTERN
          path_keys_for_attribute item
        else
          item
        end
      end
    end
  end
end
