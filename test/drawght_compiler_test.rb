require 'minitest/autorun'
require_relative '../lib/drawght'

describe 'drawght compiler' do
  def compile(template, dataset)
    Drawght::Compiler.new(template).compile dataset
  end

  describe 'when compiling' do
    it 'converts variables' do
      template = '{name} v{version} ({release date}/{start-at})'
      result = compile template, {
        name: 'Drawght',
        version: '0.1.0',
        'release date' => '2021-07-01',
        'start-at' => '2021-06-30',
      }

      expect(result).must_equal 'Drawght v0.1.0 (2021-07-01/2021-06-30)'
    end

    it 'converts hash objects' do
      template = '{product.name} - {package.name} v{package.version} ({package.release})'
      result = compile template, {
        product: {
          name: 'Drawght',
        },
        package: {
          name: 'drawght-compiler',
          version: '0.1.0',
          release: '2021-07-01',
        }
      }

      expect(result).must_equal 'Drawght - drawght-compiler v0.1.0 (2021-07-01)'
    end

    it 'converts list' do
      template = "- {tags}\n"
      result = compile template, {
        tags: %w[Text Test Tagged]
      }
      expected = "- Text\n- Test\n- Tagged\n"

      expect(result).must_equal expected
    end

    it 'converts item in a list' do
      template = "{languages#2.name} site 'https:{languages#2.url}' and {languages#1.name} site 'https:{languages#1.url}'"
      result = compile template, {
        languages: [
          { name: 'Go', url: '//go.dev/' },
          { name: 'Ruby', url: '//www.ruby-lang.org/' },
        ]
      }

      expect(result).must_equal %{Ruby site 'https://www.ruby-lang.org/' and Go site 'https://go.dev/'}

      template = "The {languages#1} programing language is a programmer's best friend"
      result = compile template, {
        languages: %w[Ruby NodeJS Go]
      }
      expect(result).must_equal "The Ruby programing language is a programmer's best friend"
    end

    it 'converts list of objects' do
      template = "- [{references:name}]({references:url})\n"
      result = compile template, {
        references: [
          { name: 'Mustache', url: '//mustache.github.io' },
          { name: 'Handlebars', url: '//handlebarsjs.com' },
        ]
      }
      expected = "- [Mustache](//mustache.github.io)\n- [Handlebars](//handlebarsjs.com)\n"

      expect(result).must_equal expected
    end

    it 'converts nested list of objects' do
      template = <<-end_text.gsub /^[ ]{8}/, ''
        - [{references:ruby.name}]({references:ruby.url})
        - [{references:nodejs.name}]({references:nodejs.url})
      end_text
      result = compile template, {
        references: [
          {
            ruby: {
              name: 'Mustache',
              url: '//mustache.github.io',
            }
          }, {
            nodejs: {
              name: 'Handlebars',
              url: '//handlebarsjs.com',
            }
          }
        ]
      }

      expect(result).must_equal <<-end_text.gsub /^[ ]{8}/, ''
        - [Mustache](//mustache.github.io)
        - [Handlebars](//handlebarsjs.com)
      end_text
    end
  end
end
