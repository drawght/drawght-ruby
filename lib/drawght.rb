# encoding: utf-8
# frozen_string_literal: true

module Drawght
  TOKENS = [
    PREFIX = '{',
    SUFFIX = '}',
    ATTRIBUTE = '.',
    ITEM = '#',
    QUERY = ':',
  ]

  PLACEHOLDERS_PATTERN = Regexp.new "\\#{PREFIX}([^\\#{SUFFIX}]+)\\#{SUFFIX}"

  ATTRIBUTES_PATTERN = Regexp.new "\\#{ATTRIBUTE}|\\#{ITEM}"
  ATTRIBUTE_PATTERN = Regexp.new "\\#{ATTRIBUTE}"
  ITEM_PATTERN = Regexp.new "\\#{ITEM}"
  QUERY_PATTERN = Regexp.new "\\#{QUERY}"

  PATH_PATTERN = Regexp.new "\\#{ATTRIBUTE}|\\#{ITEM}|\\#{QUERY}"

  module Extensions
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

      def ditch *pathkeys
        if i = pathkeys.index('&')
          list, subpath = pathkeys[0..i - 1], pathkeys[i + 1..-1]
          dig(*list).map{ |item| item.ditch *subpath }
        else
          dig *pathkeys
        end
      rescue => error
        error.message += "The pathkeys \"#{pathkeys.join ','}\" is a not valid path"
        raise error
      end
    end

    refine Array do
      def add item
        push item unless include? item
        self
      end
    end
  end

  require_relative 'drawght/parser'
  require_relative 'drawght/compiler'

  def self.load_template(template)
    Compiler.new template
  end

  def self.compile(template, data)
    load_template(template).compile data
  end
end
