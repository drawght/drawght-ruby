Gem::Specification.new do |spec|
  spec.name      = "drawght"
  spec.summary   = "Drawght parser implementation in Ruby."
  spec.authors   = ["Hallison Batista"]
  spec.email     = "email@hallison.dev.br"
  spec.homepage  = "https://github.com/drawght/drawght-ruby"
  spec.version   = %x(git describe --tags --abbrev=0)
  spec.date      = %x(git log --format='%as' --max-count=1)
  spec.licenses  = ["MIT"]
  spec.platform  = Gem::Platform::RUBY

  spec.files = %x(git ls-files).split.reject do |out|
    ignore = out =~ /([MR]ake|Gem)file/ || out =~ /^\./
    ignore = ignore || out =~ %r{^doc/api} || out =~ %r{^test/.*}
    ignore
  end

  spec.test_files = spec.files.select do |path|
    path =~ %r{^test/.*}
  end

  spec.description = <<-end.gsub /^[ ]{4}/m, ""
    Drawght is a data handler for texts without logical statements. The goal is
    to use a dataset (such as the subject of a text) to draft a document
    template. It can be considered a mini template processor.
  end

  spec.require_paths = ["lib"]
end
