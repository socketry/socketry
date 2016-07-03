lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "socketry/version"

Gem::Specification.new do |spec|
  spec.name        = "socketry"
  spec.version     = Socketry::VERSION
  spec.authors     = ["Tony Arcieri", "Zachary Anker"]
  spec.email       = ["bascule@gmail.com"]
  spec.licenses    = ["MIT"]
  spec.homepage    = "https://github.com/celluloid/socketry/"
  spec.summary     = "High-level wrappers for Ruby sockets with advanced thread-safe timeout support"
  spec.description = <<-DESCRIPTION.strip.gsub(/\s+/, " ")
    Socketry wraps Ruby's sockets with an advanced timeout engine which is able to provide multiple
    simultaneous timeout behaviors in a thread-safe way.
  DESCRIPTION

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1"

  spec.add_development_dependency "bundler", "~> 1.0"
end
