# encoding: utf-8

describe "drawght tracker" do
  class Tracker
    include Drawght::Tracker
  end

  def tracker
    @tracker ||= Tracker.new
  end

  describe "when tracking path keys" do
    describe "traces path keys" do
      dataset = {
        "author" => {
          "name" => "Isaac Asimov",
          "birhtdate" => "1920-01-02",
        },
        "series" => [
          {
            "name" => "Foundation",
            "books" => [
              { "title" => "Foundation", "year" => 1951 },
              { "title" => "Foundation and Empire", "year" => 1952 },
              { "title" => "Second Foundation", "year" => 1953 },
              { "title" => "Foundation\"s Edge", "year" => 1982 },
              { "title" => "Foundation and Earth", "year" => 1986 },
              { "title" => "Prelude to Foundation", "year" => 1988 },
              { "title" => "Forward the Foundation", "year" => 1993 },
            ]
          }, {
            "name" => "Robot",
            "books" => [
              { "title" => "The Complete Robot", "year" => 1982 },
              { "title" => "The Bicentennial Man", "year" => 1976 },
              { "title" => "Mother Earth", "year" => 1949 },
              { "title" => "The Caves of Steel", "year" => 1954 },
              { "title" => "The Naked Sun", "year" => 1957 },
              { "title" => "Mirror Image", "year" => 1972 },
              { "title" => "The Robots of Dawn", "year" => 1983 },
              { "title" => "Robots and Empire", "year" => 1985 },
            ]
          }
        ]
      }

      it "fetches value through a straightly path" do
        expect(tracker.pathing dataset, "author", "name").must_equal "Isaac Asimov"
        expect(tracker.pathing dataset, "author", "birhtdate").must_equal "1920-01-02"
      end

      it "fetches value through a sequential path" do
        expected = dataset["series"].map{ |serie| serie["name"] }

        expect(tracker.pathing dataset, "series", '&', "name").must_equal expected

        dataset.dig("series", 0, "books").each_with_index do |book, index|
          expect(tracker.pathing dataset, "series", 0, "books", index, "title").must_equal book["title"]
        end

        expected = dataset.dig("series", 0, "books").map{ |book| book["title"] }

        expect(tracker.pathing dataset, "series", 0, "books", '&', "title").must_equal expected

        expected = dataset["series"].map do |serie|
          serie["books"].map{ |book| book["title"] }
        end

        expect(tracker.pathing dataset, "series", '&', "books", '&', "title").must_equal expected

        nested_dataset = {
          "series" => {
            "name" => "Robot",
            "books" => [
              { "book" => { "title" => "The Complete Robot", "year" => 1982 } },
              { "book" => { "title" => "The Bicentennial Man", "year" => 1976 } },
              { "book" => { "title" => "Mother Earth", "year" => 1949 } },
              { "book" => { "title" => "The Caves of Steel", "year" => 1954 } },
              { "book" => { "title" => "The Naked Sun", "year" => 1957 } },
              { "book" => { "title" => "Mirror Image", "year" => 1972 } },
              { "book" => { "title" => "The Robots of Dawn", "year" => 1983 } },
              { "book" => { "title" => "Robots and Empire", "year" => 1985 } },
            ]
          }
        }
        expected = nested_dataset.dig("series", "books").map{ |books| books.dig("book", "title") }

        expect(tracker.pathing nested_dataset, "series", "books", '&', "book", "title").must_equal expected
      end

      it "raises error when uses invalid path" do
        expect{ tracker.pathing nested_dataset, "series", '&', "books", '&', "book", "title" }.must_raise StandardError
      end
    end
  end
end
