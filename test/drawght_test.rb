require "minitest/autorun"
require_relative "../lib/drawght"

describe "drawght" do
  describe "when load template" do
    it "returns compiler" do
      template = "{name} v{version} ({release date}/{start-at})"
      compiler = Drawght.load_template template

      expect(compiler).must_be_instance_of Drawght::Compiler
    end
  end

  describe "when compile" do
    it "returns template converted" do
      template = "{name} v{version} ({release date}/{start-at})"
      result = Drawght.compile template, {
        name: "Drawght",
        version: "0.1.0",
        "release date": "2021-07-01",
        "start-at" => "2021-06-30",
      }

      expect(result).must_equal "Drawght v0.1.0 (2021-07-01/2021-06-30)"
    end
  end
end
