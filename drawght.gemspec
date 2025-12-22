require_relative "lib/drawght/version"

Gem::Specification.new do |spec|
  spec.name = "drawght"
  spec.summary = "Drawght implementation in Ruby."
  spec.authors = ["Hallison Batista"]
  spec.email = "email@hallison.dev.br"
  spec.homepage = "https://drawght.github.io"
  spec.version = Drawght::VERSION || %x(git describe main --tags --abbrev=0)
  spec.date = Drawght::RELEASE_DATE || %x(git log main --format='%as' --max-count=1)
  spec.licenses = ["MIT"]
  spec.platform = Gem::Platform::RUBY
  spec.require_paths = ["lib"]

  spec.files = [
    Dir["#{spec.require_paths.first}/**/*.rb"],
    Dir["{README.md,LICENSE,CHANGELOG.yaml}"],
  ].flatten

  spec.description = <<~end_text.lstrip
    Drawght v#{Drawght::VERSION} (#{Drawght::RELEASE_DATE})

    Drawght is a data handler for texts without logical statements. The goal is
    to use a dataset (such as the subject of a text) to draft a document
    template. It can be considered a mini template processor.

    Latest changes:

    - #{Drawght::CHANGESET.join "\n- "}
  end_text
end
