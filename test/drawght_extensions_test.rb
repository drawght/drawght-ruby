# encoding: utf-8

describe "drawght extensions" do
  describe "hash extensions" do
    using Drawght::HashExtensions

    describe "#deep_stringify_keys!" do
      it "stringify all keys" do
        dataset = {
          author: {
            name: "Isaac Asimov",
            birhtdate: "1920-01-02"
          },
          books: [
            { title: "Foundation", year: 1951 },
            { title: "Foundation and Empire", year: 1952 },
            { title: "Second Foundation", year: 1953 },
          ]
        }

        result = {
          "author" => {
            "name" => "Isaac Asimov",
            "birhtdate" => "1920-01-02",
          },
          "books" => [
            { "title" => "Foundation", "year" => 1951 },
            { "title" => "Foundation and Empire", "year" => 1952 },
            { "title" => "Second Foundation", "year" => 1953 },
          ]
        }

        dataset.deep_stringify_keys!

        expect(dataset).must_equal result
      end
    end
  end


  describe "array extensions" do
    using Drawght::ArrayExtensions

    describe "#add_unique" do
      it "adds unique item" do
        list = %w[a b c d e]

        for item in list
          expect(list.add_unique item).must_equal list
        end

        list_size = list.size
        list.add_unique 'f'

        expect(list.size).must_equal list_size + 1
      end
    end
  end

  describe "string extensions" do
    using Drawght::StringExtensions

    describe "#to_placeholder" do
      it "applies the placeholder format" do
        expect("name".to_placeholder).must_equal "{name}"
      end
    end
  end
end
