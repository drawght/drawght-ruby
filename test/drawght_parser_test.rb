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

  def expect_pathkeys(from:, must_equal:)
    result = parser.pathkeys_from from
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

  describe "when parses path keys" do
    it "parses the variable syntax path" do
      templates = [
        "author",
        "book title",
        "collection-name",
      ]

      for template in templates
        expect_pathkeys from: template, must_equal: [template]
      end
    end

    it "parses the attribute syntax path" do
      expectations = {
        "author.name" => ["author", "name"],
        "user.last access" => ["user", "last access"],
        "user.created-at" => ["user", "created-at"],
      }

      for (template, expected) in expectations
        expect_pathkeys from: template, must_equal: expected
      end
    end

    describe "when parses collection syntax" do
      it "parses the main syntax" do
        (0..9).each do |index|
          expect_pathkeys from: "##{index + 1}", must_equal: [index]
          expect_pathkeys from: "##{index + 1}.Title", must_equal: [index, "Title"]
        end
      end

      it "parses the attribute syntax" do
        (0..9).each do |index|
          expect_pathkeys from: "Books##{index + 1}", must_equal: ["Books", index]
        end
      end

      it "parses the nested syntax" do
        (0..9).each do |index|
          expect_pathkeys from: "Books##{index + 1}.Title", must_equal: ["Books", index, "Title"]
        end

        expect_pathkeys from: "Books:Title", must_equal: ["Books", "&", "Title"]

        expect_pathkeys from: "Series:Books:Title", must_equal: %w[Series & Books & Title]

        expect_pathkeys from: "Series#1.Books:Title", must_equal: ["Series", 0, "Books", "&", "Title"]

        (0..1).each do |serie|
          (0..1).each do |book|
            expect_pathkeys **{
              from: "Series##{serie + 1}.Books##{book + 1}.Title",
              must_equal: ["Series", serie, "Books", book, "Title"]
            }
          end
        end
      end

      it "does parsing the last item" do
        expect_pathkeys from: 'Changelog#$.Version', must_equal: ["Changelog", -1, "Version"]
        expect_pathkeys from: "Changelog#0.Version", must_equal: ["Changelog", -1, "Version"]
      end

      it "does parsing the collection size syntax" do
        skip
      end
    end
  end

  describe "when parses placeholders" do
    it "gets all placeholders from text" do
      expectations = {
        "The {author.name} has {author.age} years old" => %w[author.name author.age],
        "The author {author.name} wrotte the following books:\n- {author.books:title}" => [
          "author.name",
          "author.books:title",
        ]
      }

      for (template, expected) in expectations
        expect_placeholders from: template, must_equal: expected
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
      #       "Tests" => {
      #         "Unit" => [
      #           { "Models" => [ "Person", "User" ],
      #           { "Controllers" => [ "PersonController", "UserController", "AccessController" ] },
      #         ]
      #       }
      #     }
      #   ]
      # }

      expectations = {
        "{Name} v{Changelog#2.Version} ({Changelog#2.Release})" => {
          straightly_placeholders: [
            "Name",
            "Changelog#2.Version",
            "Changelog#2.Release",
          ],
        },
        "- {Name} v{Changelog:Version} - {Changelog:Release}" => {
          straightly_placeholders: ["Name"],
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
        }
      }

      for (template, expected) in expectations
        expect_placeholders_mapping from: template, must_equal: expected
      end
    end
  end
end
