# encoding: utf-8

describe "drawght parser" do
  class Parser
    include Drawght::Parser
  end

  def parser
    @parser ||= Parser.new
  end

  # dataset = {
  #   "Author" => {
  #     "Name" => "Isaac Asimov",
  #     "Birhtdate" => "1920-01-02",
  #   },
  #   "Series" => [
  #     {
  #       "Name" => "Foundation",
  #       "Books" => [
  #         { "Title" => "Foundation", "Year" => 1951 },
  #         { "Title" => "Foundation and Empire", "Year" => 1952 },
  #         { "Title" => "Second Foundation", "Year" => 1953 },
  #         { "Title" => "Foundation\"s Edge", "Year" => 1982 },
  #         { "Title" => "Foundation and Earth", "Year" => 1986 },
  #         { "Title" => "Prelude to Foundation", "Year" => 1988 },
  #         { "Title" => "Forward the Foundation", "Year" => 1993 },
  #       ]
  #     }, {
  #       "Name" => "Robot",
  #       "Books" => [
  #         { "Title" => "The Complete Robot", "Year" => 1982 },
  #         { "Title" => "The Bicentennial Man", "Year" => 1976 },
  #         { "Title" => "Mother Earth", "Year" => 1949 },
  #         { "Title" => "The Caves of Steel", "Year" => 1954 },
  #         { "Title" => "The Naked Sun", "Year" => 1957 },
  #         { "Title" => "Mirror Image", "Year" => 1972 },
  #         { "Title" => "The Robots of Dawn", "Year" => 1983 },
  #         { "Title" => "Robots and Empire", "Year" => 1985 },
  #       ]
  #     }
  #   ]
  # }

  describe "when parsing syntax" do
    syntax_validations = {
      structural: {
        "name" => true,
        "_name" => true,
        "variable name" => true,
        "variable-name" => true,
        "_variable _name" => true,
        "_variable-_name" => true,
        "#1" => true,
        "#1001" => true,
        '#$' => true,
        "items#1" => true,
        "items#1001" => true,
        'items#$' => true,
        "items#&" => true,
        '#1#$' => false,
        '#$#1' => false,
        "struct.attribute" => true,
        "struct.attribute.field.property" => true,
        "_struct._attribute" => true,
        "struct name.attribute" => true,
        "struct-name.attribute" => true,
        "struct.attribute name" => true,
        "struct.attribute-name" => true,
        "struct.items#1" => true,
        "struct.items#101" => true,
        'struct.items#$' => true,
        "struct.items#&" => true,
        "struct .attribute" => false,
        "struct. attribute" => false,
        "#1.name" => true,
        '#1.attribute-name' => true,
        '#1.attribute name' => true,
        '#$.name' => true,
        '#$.attribute name' => true,
        '#$.attribute-name' => true,
        "items#1.subitems#1.attribute" => true,
        "items#2.subitems#1.attributes#1.name" => true,
        "items#1.attribute" => true,
        'items#$.attribute' => true,
        "items#1#2.attribute" => false,
        "items*" => false,
        "items*subitems*" => false,
        ".name" => false,
        "name." => false,
        "struct..attribute" => false,
        "items**" => false,
        "struct.:attribute" => false,
        "items.$" => false,
      },
      sequential: {
        ":attribute" => true,
        ":collection:attribute" => true,
        ":items#1" => true,
        ":items#1001" => true,
        ":items#1.attribute" => true,
        ":items*" => false,
        ":items#&" => true,
        "::attribute" => false,
        "collection:attribute" => true,
        "items:collection:attribute" => true,
        "another items:collection:attribute" => true,
        "another-items:collection:attribute" => true,
        "items#1.collection:attribute" => true,
        "this.is.valid:to.get.value" => true,
        "struct.collection:noitcelloc.tcurts:attribute" => true,
        "items:subitems#&" => true,
        "items:subitems*" => false,
        "items*:attribute" => false,
        "items::attribute" => false,
        "items:" => false,
        "items:*" => false,
        "items:#1" => false,
        'items:#$' => false,
        'items:#&' => false,
        'items$:' => false,
      },
      errors: {
        "" => false,
        " " => false,
        "." => false,
        "#" => false,
        ":" => false,
        "*" => false,
      }
    }

    %i[structural sequential errors].each do |mode|
      it "validates #{mode} path syntax" do
        for (template, expected) in syntax_validations[mode]
          expect(parser.syntax_valid? template).must_equal expected, "#{template} => #{Regexp.last_match&.names}"
        end
      end
    end
  end

  describe "when parsing path keys" do
    it "parses the variable syntax path" do
      templates = [
        "author",
        "book title",
        "collection-name",
      ]

      for template in templates
        expect(parser.pathkeys_from template).must_equal [template]
      end
    end

    it "parses the attribute syntax path" do
      expectations = {
        "author.name" => ["author", "name"],
        "user.last access" => ["user", "last access"],
        "user.created-at" => ["user", "created-at"],
      }

      for (template, expected) in expectations
        expect(parser.pathkeys_from template).must_equal expected
      end
    end

    describe "when parsing collection syntax" do
      it "parses the main syntax" do
        (0..9).each do |index|
          expect(parser.pathkeys_from "##{index + 1}").must_equal [index]
          expect(parser.pathkeys_from "##{index + 1}.Title").must_equal [index, "Title"]
        end
      end

      it "parses the attribute syntax" do
        (0..9).each do |index|
          expect(parser.pathkeys_from "Books##{index + 1}").must_equal ["Books", index]
        end
      end

      it "parses the nested syntax" do
        (0..9).each do |index|
          expect(parser.pathkeys_from "Books##{index + 1}.Title").must_equal [
            "Books", index, "Title"
          ]
        end

        expect(parser.pathkeys_from "Books:Title").must_equal [
          "Books", Parser::CONTEXT, "Title"
        ]

        expect(parser.pathkeys_from "Series:Books:Title").must_equal [
          "Series", Parser::CONTEXT, "Books", Parser::CONTEXT, "Title"
        ]

        expect(parser.pathkeys_from "Series#1.Books:Title").must_equal [
          "Series", 0, "Books", Parser::CONTEXT, "Title"
        ]

        (0..1).each do |serie|
          (0..1).each do |book|
            template = "Series##{serie + 1}.Books##{book + 1}.Title"
            expected = ["Series", serie, "Books", book, "Title"]
            expect(parser.pathkeys_from template).must_equal expected
          end
        end
      end

      it "parses the last item syntax" do
        expect(parser.pathkeys_from 'Changelog#$.Version').must_equal ["Changelog", -1, "Version"]
        expect(parser.pathkeys_from "Changelog#0.Version").must_equal ["Changelog", -1, "Version"]
      end

      it "parses the collection size syntax" do
        expect(parser.pathkeys_from "Changelog#&").must_equal [
          "Changelog", Parser::LENGTH
        ]

        expect(parser.pathkeys_from "Changelog#1.Changes#&").must_equal [
          "Changelog", 0, "Changes", Parser::LENGTH
        ]
      end
    end
  end

  describe "when parsing placeholders" do
    it "gets all placeholders from text" do
      expectations = {
        "The {author.name} has {author.age} years old" => %w[author.name author.age],
        "The author {author.name} wrotte the following books:\n- {author.books:title}" => [
          "author.name",
          "author.books:title",
        ]
      }

      for (template, expected) in expectations
        expect(parser.placeholders_from template).must_equal expected
      end
    end
  end

  describe "when mapping placeholders" do
    it "maps all placeholders from text" do
      # dataset = {
      #   "Name" => "Drawght",
      #   "Changelog" => [
      #     {
      #       "Version" => "0.1.0",
      #       "Release" => "2021-07-11",
      #       "Summary" => "Work in progress!",
      #       "Changes" => [
      #         "Variables",
      #         "Objects",
      #         "Lists",
      #       ]
      #     }, {
      #       "Version" => "0.2.0",
      #       "Release" => "2024-08-30",
      #       "Summary" => "Tests and tests.",
      #       "Changes" => [
      #         "Tests for variables",
      #         "Tests for objects",
      #         "Tests for lists",
      #       ],
      #     },
      #   ],
      #   "Tests" => {
      #     "Unit" => [
      #       {
      #         "Models" => [
      #           "Person",
      #           "User"
      #         ]
      #       }, {
      #         "Controllers" => [
      #           "PersonController",
      #           "UserController",
      #           "AccessController"
      #         ]
      #       },
      #     ]
      #   }
      # }

      expectations = {
        "{Name} v{Changelog#2.Version} ({Changelog#2.Release})" => {
          structural_placeholders: [
            "Name",
            "Changelog#2.Version",
            "Changelog#2.Release",
          ],
          sequential_placeholders: {},
        },
        '- {Name} v{Changelog#$.Version} - {Changelog#$.Release}' => {
          structural_placeholders: [
            "Name",
            'Changelog#$.Version',
            'Changelog#$.Release',
          ],
          sequential_placeholders: {},
        },
        "- {Name} v{Changelog:Version} - {Changelog:Release}" => {
          structural_placeholders: ["Name"],
          sequential_placeholders: {
            "Changelog" => {
              "Changelog:Version" => "Version",
              "Changelog:Release" => "Release"
            },
          }
        },
        "- v{Changelog:Version} > {Tests:Unit:Models} {Tests:Unit:Controllers}" => {
          sequential_placeholders: {
            "Changelog" => {
              "Changelog:Version" => "Version",
            },
            "Tests:Unit" => {
              "Tests:Unit:Models" => "Models",
              "Tests:Unit:Controllers" => "Controllers",
            },
          }
        },
        "- v{Changelog:Version} > {Tests:Unit:Models*} {Tests:Unit:Controllers*}" => {
          sequential_placeholders: {
            "Changelog" => {
              "Changelog:Version" => "Version",
            },
            "Tests:Unit" => {
              "Tests:Unit:Models*" => "Models*",
              "Tests:Unit:Controllers*" => "Controllers*",
            },
          }
        }
      }

      for (template, expected) in expectations
        parser.mapping_placeholders_from template

        expected.each do |navigation, placeholders|
          expect(parser.send navigation).must_equal placeholders
        end
      end
    end
  end
end
