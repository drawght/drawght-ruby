# encoding: utf-8

require 'minitest/autorun'
require_relative '../lib/drawght'

describe 'drawght parser' do
  include Drawght::Parser

  def expect_path_keys(from:, must_equal:)
    result = path_keys_from from
    expect(result).must_equal must_equal
  end

  def expect_placeholders(from:, must_equal:)
    result = placeholders_from from
    expect(result).must_equal must_equal
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

    it 'parses the main list syntax path' do
      (0..9).each do |index|
        expect_path_keys from: "##{index + 1}", must_equal: [index]
        expect_path_keys from: "##{index + 1}.Title", must_equal: [index, 'Title']
      end
    end

    it 'parses the attribute list syntax path' do
      (0..9).each do |index|
        expect_path_keys from: "Books##{index + 1}", must_equal: ['Books', index]
      end
    end

    it 'parses the nested list syntax path' do
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
end
