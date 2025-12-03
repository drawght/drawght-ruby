# encoding: utf-8
# frozen_string_literal: true

module Drawght
  module Parser
    using Extensions

    def pathkeys_from placeholder
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

    def mapping_placeholders_from string
      clear_placeholder_mappings!

      placeholders_from(string).map do |placeholder|
        if placeholder =~ QUERY_PATTERN
          placeholder.scan %r/^(.*)#{QUERY}(.*)$/ do |pathkeys, attribute|
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

    def replace_placeholders template, value
      case value
      when Hash
        replace_placeholder_attributes_for template, value
      when Array
        replace_placeholder_collections_for template, value
      else
        replace_placeholder_variables_from template, value
      end
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

    def clear_placeholder_mappings!
      straightly_placeholders.clear && sequential_placeholders.clear
    end
  end
end
