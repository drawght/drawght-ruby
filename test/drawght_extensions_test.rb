# encoding: utf-8

require 'minitest/autorun'
require_relative '../lib/drawght'

describe 'drawght extensions' do
  using Drawght::Extensions

  it 'adds Hash#deep_stringify_keys!' do
    dataset = {
      author: {
        name: 'Isaac Asimov',
        birhtdate: '1920-01-02'
      },
      books: [
        { title: 'Foundation', year: 1951 },
        { title: 'Foundation and Empire', year: 1952 },
        { title: 'Second Foundation', year: 1953 },
      ]
    }

    result = {
      'author' => {
        'name' => 'Isaac Asimov',
        'birhtdate' => '1920-01-02',
      },
      'books' => [
        { 'title' => 'Foundation', 'year' => 1951 },
        { 'title' => 'Foundation and Empire', 'year' => 1952 },
        { 'title' => 'Second Foundation', 'year' => 1953 },
      ]
    }

    expect(dataset.deep_stringify_keys!).must_equal result
  end

  it 'adds Hash#dig' do
    dataset = {
      'author' => {
        'name' => 'Isaac Asimov',
        'birhtdate' => '1920-01-02',
      },
      'series' => [
        {
          'name' => 'Foundation',
          'books' => [
            { 'title' => 'Foundation', 'year' => 1951 },
            { 'title' => 'Foundation and Empire', 'year' => 1952 },
            { 'title' => 'Second Foundation', 'year' => 1953 },
            { 'title' => 'Foundation\'s Edge', 'year' => 1982 },
            { 'title' => 'Foundation and Earth', 'year' => 1986 },
            { 'title' => 'Prelude to Foundation', 'year' => 1988 },
            { 'title' => 'Forward the Foundation', 'year' => 1993 },
          ]
        }, {
          'name' => 'Robot',
          'books' => [
            { 'title' => 'The Complete Robot', 'year' => 1982 },
            { 'title' => 'The Bicentennial Man', 'year' => 1976 },
            { 'title' => 'Mother Earth', 'year' => 1949 },
            { 'title' => 'The Caves of Steel', 'year' => 1954 },
            { 'title' => 'The Naked Sun', 'year' => 1957 },
            { 'title' => 'Mirror Image', 'year' => 1972 },
            { 'title' => 'The Robots of Dawn', 'year' => 1983 },
            { 'title' => 'Robots and Empire', 'year' => 1985 },
          ]
        }
      ]
    }

    expect(dataset.dig 'author', 'name').must_equal 'Isaac Asimov'
    expect(dataset.dig 'author', 'birhtdate').must_equal '1920-01-02'

    expected = dataset['series'].map{ |serie| serie['name'] }
    expect(dataset.dig 'series', '&', 'name').must_equal expected

    dataset['series'][0]['books'].each_with_index do |book, index|
      expect(dataset.dig 'series', 0, 'books', index, 'title').must_equal book['title']
    end

    expected = dataset['series'][0]['books'].map{ |book| book['title'] }

    expect(dataset.dig 'series', 0, 'books', '&', 'title').must_equal expected

    expected = dataset['series'].map do |serie|
      serie['books'].map{ |book| book['title'] }
    end

    expect(dataset.dig 'series', '&', 'books', '&', 'title').must_equal expected
  end
end
