# encoding: utf-8
# frozen_string_literal: true

module Drawght
  module ArrayExtensions
    refine Array do
      def add_unique item
        push item unless include? item
        self
      end
    end
  end

  module Parser
    using ArrayExtensions

    TOKENS = [
      PREFIX = '{',
      SUFFIX = '}',
      ACCESSOR = '.',
      INDEX = '#',
      SCOPE = ':',
      CONTEXT = '@',
      LAST = '$',
      LENGTH = '&',
    ]

    # Identifiers/name matches:
    #
    # - "name"
    # - "variable name"
    # - "variable-name"
    # - "variable_name"
    # - "_name_"
    # - "name_"
    # - "_name"
    IDENTIFIER_MATCHES = "[A-Za-z_][A-Za-z0-9_\\-]*(?: [A-Za-z0-9_\\-]+)*"

    # Index/item matches:
    #
    # - "#1" for first item.
    # - "#n" for n-th item.
    # - "#$" for last item.
    INDEX_MATCHES = "\\#{INDEX}(?:\\d+|\\#{LAST})"

    # Element matches:
    #
    # - "items#1" for first named item.
    # - "items#n" for n-th named item.
    # - "items#$" for last named item.
    #
    # Matches with IDENTIFIER_MATCHES and INDEX_MATCHES.
    ELEMENT_MATCHES = "#{IDENTIFIER_MATCHES}(?:#{INDEX_MATCHES})?"

    # Attribute matches.
    ATTRIBUTE_MATCHES = "\\#{ACCESSOR}(?:#{ELEMENT_MATCHES})"

    # Validation
    #
    # Structural matches:
    #
    # - "struct.attribute" for attribute value from struct.
    # - "struct.substruct.attribute" for attribute value of the substruct from
    #   struct.
    # - "struct.items#1" for first item value in items of the struct.
    # - "struct.items#1.attribute" for attribute value of the first item in
    #   items of the struct.
    # - "#1.attribute" for attribute value of the first item.
    # - "#1.struct.attribute" for attribute value of the struct from the first item.
    # - "items#1.attribute" for attribute value of the first item in items.
    # - "items#1.struct.attribute" for attribute value of the struct of the
    #   first item in items.
    # - "items#1.subitems#1" for subitem value of the first item in items.
    # - "items#1.subitems#1.attribute" for attribute value of the subitem from
    #   first item in items.
    #
    # Scoped matches:
    #
    # ":attribute"
    # ":collection:attribute"
    # "collection:attribute"
    # "collection:subcollection:attribute"
    # "items#1:attribute"
    # "struct.collection:attribute"
    # "items#1.collection:attribute"
    # "items#1.subitems#1:attribute"
    # "items#1.subitems#1.collection:attribute"
    # "struct.collection:noitcelloc.tcurts:attribute"
    VALIDATION_PATTERN = Regexp.new "^(?=.*[A-Za-z_\\#{INDEX}])(?:(?:#{ELEMENT_MATCHES}|#{INDEX_MATCHES})(?:#{ATTRIBUTE_MATCHES})*)?(?:\\#{SCOPE}(?:#{ELEMENT_MATCHES})(?:#{ATTRIBUTE_MATCHES})*)*(?:\\#{INDEX}\\#{LENGTH})?$"

    PLACEHOLDERS_PATTERN = Regexp.new "\\#{PREFIX}([^\\#{SUFFIX}]+)\\#{SUFFIX}"
    STRUCTURE_TOKEN_PATTERN = Regexp.new "(\\#{ACCESSOR}|\\#{INDEX}|\\#{LENGTH}$)"
    SCOPE_TOKEN_PATTERN = Regexp.new "(\\#{SCOPE})"
    SCOPE_PATH_PATTERN = Regexp.new "^(.*)#{SCOPE_TOKEN_PATTERN}(.*)$"

    NUMBER_PATTERN = /^\d+/

    using ArrayExtensions

    class SyntaxError < StandardError
      def initialize syntax
        super "Invalid syntax for \"#{syntax}\""
      end
    end

    def pathkeys_from string
      raise SyntaxError.new string unless syntax_valid? string

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

    def syntax_valid? string
      string.match? VALIDATION_PATTERN
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
          structural_placeholders.add_unique placeholder
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

    def has_placeholders? string
      string.match? PLACEHOLDERS_PATTERN
    end

    def pathize string
      "#{PREFIX}#{string}#{SUFFIX}"
    end

    private

    def pathkeys_for_structure placeholder
      placeholder
        .split(STRUCTURE_TOKEN_PATTERN)
        .reject{ |expression| [ACCESSOR, INDEX].include? expression }
        .map do |expression|
          value = zeroize expression

          if value =~ SCOPE_TOKEN_PATTERN
            pathkeys_for_collection expression
          else
            value =~ NUMBER_PATTERN ? value.to_i - 1 : expression unless value.empty?
          end
        end.compact
    end

    def zeroize value, token: LAST
      value.to_s.sub token, '0'
    end

    def pathkeys_for_collection placeholder
      placeholder.split(SCOPE_TOKEN_PATTERN).map do |expression|
        case expression.to_s
        when STRUCTURE_TOKEN_PATTERN then
          pathkeys_for_structure expression
        when SCOPE then
          CONTEXT
        else
          expression
        end
      end
    end

    def clear_placeholder_mappings!
      structural_placeholders.clear && sequential_placeholders.clear
    end
  end
end
