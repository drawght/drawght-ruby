# encoding: utf-8
# frozen_string_literal: true

module Drawght
  module Parser
    TOKENS = [
      ACCESSOR = '.',
      INDEX = '#',
      SCOPE = ':',
      CONTEXT = '@',
      LAST = '$',
      LENGTH = '&',
    ]

    STRUCTURE_TOKEN_PATTERN = Regexp.new "(\\#{ACCESSOR}|\\#{INDEX}|\\#{LENGTH}$)"
    SCOPE_TOKEN_PATTERN = Regexp.new "(\\#{SCOPE})"
    SCOPE_PATH_PATTERN = Regexp.new "^(.*)#{SCOPE_TOKEN_PATTERN}(.*)$"

    NUMBER_PATTERN = /^\d+/

    using ArrayExtensions

    def pathkeys_from string
      path = case string
        when STRUCTURE_TOKEN_PATTERN then
          pathkeys_for_structure string
        when SCOPE_TOKEN_PATTERN then
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
        if placeholder =~ SCOPE_TOKEN_PATTERN
          placeholder.scan SCOPE_PATH_PATTERN do |pathkeys, _delimiter, attribute|
            (sequential_placeholders[pathkeys] ||= {}).update placeholder => attribute
          end
        else
          structural_placeholders.add placeholder
        end

        placeholder
      end
    end

    def structural_placeholders
      @structural_placeholders ||= []
    end

    def sequential_placeholders
      @sequential_placeholders ||= {}
    end

    private

    def pathkeys_for_structure placeholder
      placeholder
        .split(STRUCTURE_TOKEN_PATTERN)
        .reject{ |holding| [ACCESSOR, INDEX].include? holding }
        .map do |holding|
          value = attribute_holding_from holding

          if value =~ SCOPE_TOKEN_PATTERN
            pathkeys_for_collection holding
          else
            value =~ NUMBER_PATTERN ? value.to_i - 1 : holding unless value.empty?
          end
        end.compact
    end

    def attribute_holding_from value
      value.to_s.sub LAST, '0'
    end

    def pathkeys_for_collection placeholder
      placeholder.split(SCOPE_TOKEN_PATTERN).map do |holding|
        case holding.to_s
        when STRUCTURE_TOKEN_PATTERN then
          pathkeys_for_structure holding
        when SCOPE then
          CONTEXT
        else
          holding
        end
      end
    end

    def clear_placeholder_mappings!
      structural_placeholders.clear && sequential_placeholders.clear
    end
  end
end
