# encoding: utf-8

require 'minitest/autorun'
require_relative '../lib/drawght'

class Parser
  include Drawght::Parser
end

describe 'drawght parser' do
  def parser
    @parser ||= Parser.new
  end

  def expect_path_keys(from:, must_equal:)
    result = parser.path_keys_from from
    expect(result).must_equal must_equal
  end

  def expect_placeholders(from:, must_equal:)
    result = parser.placeholders_from from
    expect(result).must_equal must_equal
  end

  def expect_placeholders_mapping(from:, must_equal:)
    parser.mapping_placeholders_from from

    must_equal.each do |navigation, placeholders|
      expect(parser.send navigation).must_equal placeholders
    end
  end

  describe 'when parses path keys' do
    it 'parses the variable syntax path' do
      templates = [
        'author',
        'book title',
        'collection-name',
      ]

      for template in templates
        expect_path_keys from: template, must_equal: [template]
      end
    end

    it 'parses the attribute syntax path' do
      expectations = {
        'author.name' => ['author', 'name'],
        'user.last access' => ['user', 'last access'],
        'user.created-at' => ['user', 'created-at'],
      }

      for (template, expected) in expectations
        expect_path_keys from: template, must_equal: expected
      end
    end

    it 'parses the main collection syntax path' do
      (0..9).each do |index|
        expect_path_keys from: "##{index + 1}", must_equal: [index]
        expect_path_keys from: "##{index + 1}.Title", must_equal: [index, 'Title']
      end
    end

    it 'parses the attribute collection syntax path' do
      (0..9).each do |index|
        expect_path_keys from: "Books##{index + 1}", must_equal: ['Books', index]
      end
    end

    it 'parses the nested collection syntax path' do
      (0..9).each do |index|
        expect_path_keys from: "Books##{index + 1}.Title", must_equal: ['Books', index, 'Title']
      end

      # dataset = {
      #   'Books' => [
      #     { 'Title' => 'One' },
      #     { 'Title' => 'Two' },
      #   ]
      # }

      expect_path_keys from: 'Books:Title', must_equal: ['Books', '&', 'Title']

      # dataset = {
      #   'Series' => [
      #     {
      #       'Name' => 'Serie One',
      #       'Books' => [
      #         { 'Title' => 'Serie One - Book One' },
      #         { 'Title' => 'Serie One - Book Two' },
      #       ]
      #     }, {
      #       'Name' => 'Serie Two',
      #       'Books' => [
      #         { 'Title' => 'Serie Two - Book One' },
      #         { 'Title' => 'Serie Two - Book Two' },
      #       ]
      #     }
      #   ]
      # }

      expect_path_keys from: 'Series:Books:Title', must_equal: %w[Series & Books & Title]

      expect_path_keys from: 'Series#1.Books:Title', must_equal: ['Series', 0, 'Books', '&', 'Title']

      (0..1).each do |serie|
        (0..1).each do |book|
          expect_path_keys **{
            from: "Series##{serie + 1}.Books##{book + 1}.Title",
            must_equal: ['Series', serie, 'Books', book, 'Title']
          }
        end
      end
    end
  end

  describe 'when parses placeholders' do
    it 'gets all placeholders from text' do
      expectations = {
        'The {author.name} has {author.age} years old' => %w[author.name author.age],
        "The author {author.name} wrotte the following books:\n- {author.books:title}" => [
          'author.name',
          'author.books:title',
        ]
      }

      for (template, expected) in expectations
        expect_placeholders from: template, must_equal: expected
      end
    end
  end

  describe 'when mapping placeholders' do
    it 'maps all placeholders from text' do
      # dataset = {
      #   'Name' => 'Drawght',
      #   'Changelog' => [
      #     {
      #       'Version' => '0.1.0',
      #       'Release' => '2021-07-11',
      #       'Summary' => 'Work in progress!',
      #       'Changes' => [
      #         'Variables',
      #         'Objects',
      #         'Lists',
      #       ]
      #     }, {
      #       'Version' => '0.2.0',
      #       'Release' => '2024-08-30',
      #       'Summary' => 'Tests and tests.',
      #       'Changes' => [
      #         'Tests for variables',
      #         'Tests for objects',
      #         'Tests for lists',
      #       ],
      #       'Tests' => {
      #         'Unit' => [
      #           { 'Models' => [ 'Person', 'User' ],
      #           { 'Controllers' => [ 'PersonController', 'UserController', 'AccessController' ] },
      #         ]
      #       }
      #     }
      #   ]
      # }

      expectations = {
        '{Name} v{Changelog#2.Version} ({Changelog#2.Release})' => {
          straightly_placeholders: [
            'Name',
            'Changelog#2.Version',
            'Changelog#2.Release',
          ],
        },
        '- {Name} v{Changelog:Version} - {Changelog:Release}' => {
          straightly_placeholders: ['Name'],
          sequential_placeholders: {
            'Changelog' => {
              'Changelog:Version' => 'Version',
              'Changelog:Release' => 'Release'
            },
          }
        },
        '- v{Changelog:Version} > {Tests:Unit:Models} {Tests:Unit:Controllers}' => {
          sequential_placeholders: {
            'Changelog' => {
              'Changelog:Version' => 'Version',
            },
            'Tests:Unit' => {
              'Tests:Unit:Models' => 'Models',
              'Tests:Unit:Controllers' => 'Controllers',
            },
          }
        }
      }

      for (template, expected) in expectations
        expect_placeholders_mapping from: template, must_equal: expected
      end
    end
  end
end
