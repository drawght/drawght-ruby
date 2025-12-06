# encoding: utf-8
# frozen_string_literal: true

module Drawght
  TOKENS = [
    PREFIX = '{',
    SUFFIX = '}',
  ]

  PLACEHOLDERS_PATTERN = Regexp.new "\\#{PREFIX}([^\\#{SUFFIX}]+)\\#{SUFFIX}"

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

  module ArrayExtensions
    refine Array do
      def add item
        push item unless include? item
        self
      end
    end
  end

  module StringExtensions
    refine String do
      def to_placeholder
        "#{PREFIX}#{self}#{SUFFIX}"
      end
    end
  end

  module AllExtensions
    include HashExtensions
    include ArrayExtensions
    include StringExtensions
  end

  require_relative "drawght/parser"
  require_relative "drawght/compiler"
  require_relative "drawght/version"

  def self.load_template(template)
    Compiler.new template
  end

  def self.compile(template, data)
    load_template(template).compile data
  end
end
