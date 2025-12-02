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

    dataset.deep_stringify_keys!

    expect(dataset).must_equal result
  end

  it 'adds Hash#ditch' do
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

    expect(dataset.ditch 'author', 'name').must_equal 'Isaac Asimov'
    expect(dataset.ditch 'author', 'birhtdate').must_equal '1920-01-02'

    expected = dataset['series'].map{ |serie| serie['name'] }
    expect(dataset.ditch 'series', '&', 'name').must_equal expected

    dataset.dig('series', 0, 'books').each_with_index do |book, index|
      expect(dataset.ditch 'series', 0, 'books', index, 'title').must_equal book['title']
    end

    expected = dataset.dig('series', 0, 'books').map{ |book| book['title'] }

    expect(dataset.ditch 'series', 0, 'books', '&', 'title').must_equal expected

    expected = dataset['series'].map do |serie|
      serie['books'].map{ |book| book['title'] }
    end

    expect(dataset.ditch 'series', '&', 'books', '&', 'title').must_equal expected

    dataset = {
      'series' => {
        'name' => 'Robot',
        'books' => [
          { 'book' => { 'title' => 'The Complete Robot', 'year' => 1982 } },
          { 'book' => { 'title' => 'The Bicentennial Man', 'year' => 1976 } },
          { 'book' => { 'title' => 'Mother Earth', 'year' => 1949 } },
          { 'book' => { 'title' => 'The Caves of Steel', 'year' => 1954 } },
          { 'book' => { 'title' => 'The Naked Sun', 'year' => 1957 } },
          { 'book' => { 'title' => 'Mirror Image', 'year' => 1972 } },
          { 'book' => { 'title' => 'The Robots of Dawn', 'year' => 1983 } },
          { 'book' => { 'title' => 'Robots and Empire', 'year' => 1985 } },
        ]
      }
    }
    expected = dataset.dig('series', 'books').map{ |books| books.dig('book', 'title') }

    expect{ dataset.ditch 'series', '&', 'books', '&', 'book', 'title' }.must_raise StandardError

    expect(dataset.ditch 'series', 'books', '&', 'book', 'title').must_equal expected
  end

  it 'adds Array#add' do
    list = %w[a b c d e]

    for item in list
      expect(list.add item).must_equal list
    end

    list_size = list.size
    list.add 'f'

    expect(list.size).must_equal list_size + 1
  end

  it 'adds String#to_placeholder' do
    expect('name'.to_placeholder).must_equal '{name}'
  end
end
