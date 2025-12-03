# encoding: utf-8

describe "drawght compiler" do
  require "date"

  def compile(template, dataset)
    Drawght::Compiler.new(template).compile dataset
  end

  describe "when compiling" do
    dataset = {
      Name: "Drawght",
      Version: "0.1.0",
      "Release Date" => "2021-07-01",
      "Start-at" => "2021-06-30",
      Changelog: [
        {
          Version: "0.1.0",
          Release: "2021-07-11",
          Summary: "Work in progress!",
          Changes: [
            "Variables",
            "Objects",
            "Lists",
          ]
        }, {
          Version: "0.2.0",
          Release: "2024-08-30",
          Summary: "Tests and tests.",
          Changes: [
            "Tests for variables",
            "Tests for objects",
            "Tests for lists",
          ]
        }
      ],
      Package: {
        Name: "drawght-compiler",
        Version: "0.1.0",
        Release: "2021-07-01"
      },
      Tags: [
        "Text",
        "Parsing",
        "Test",
      ]
    }

    it "converts variables, attributes and items" do
      expections = {
        "{Name} v{Version} ({Release Date}/{Start-at})" => "Drawght v0.1.0 (2021-07-01/2021-06-30)",
        "{Name} - {Package.Name} v{Package.Version} ({Package.Release})" => "Drawght - drawght-compiler v0.1.0 (2021-07-01)",
        "- {Tags}\n" => "- Text\n- Parsing\n- Test\n",
      }

      for (template, expected) in expections
        expect(compile template, dataset).must_equal expected
      end
    end

    it "converts straightly items in a collection" do
      template = <<~end_text.lstrip
        Changelog for {Changelog#1.Version} released in {Changelog#1.Release}.
        Changes:
        - {Changelog#1.Changes}
      end_text
      expection = <<~end_text.lstrip
        Changelog for 0.1.0 released in 2021-07-11.
        Changes:
        - Variables
        - Objects
        - Lists
      end_text

      expect(compile template, dataset).must_equal expection
    end

    it "converts collection of objects" do
      template = "- [{references:name}]({references:url})\n"
      result = compile template, {
        references: [
          { name: "Mustache", url: "//mustache.github.io" },
          { name: "Handlebars", url: "//handlebarsjs.com" },
        ]
      }
      expected = "- [Mustache](//mustache.github.io)\n- [Handlebars](//handlebarsjs.com)\n"

      expect(result).must_equal expected
    end

    it "converts nested collection of objects" do
      template = <<-end_text.lstrip
        - [{references:language.name}]({references:language.url})
      end_text

      result = compile template, {
        references: [
          {
            language: {
              name: "Mustache",
              url: "//mustache.github.io",
            }
          }, {
            language: {
              name: "Handlebars",
              url: "//handlebarsjs.com",
            }
          }
        ]
      }

      expect(result).must_equal <<~end_text.lstrip
        - [Mustache](//mustache.github.io)
        - [Handlebars](//handlebarsjs.com)
      end_text
    end

    it 'converts dates' do
      today = Date.today
      data = {
        Release: today
      }

      expect(compile "{Release}", data).must_equal "#{today}"
    end
  end
end
