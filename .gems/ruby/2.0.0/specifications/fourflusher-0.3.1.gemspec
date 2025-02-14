# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fourflusher"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Boris Bu\u{308}gling"]
  s.bindir = "exe"
  s.date = "2016-05-30"
  s.email = ["boris@icculus.org"]
  s.homepage = "https://github.com/neonichu/fourflusher"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.14.1"
  s.summary = "A library for interacting with Xcode simulators."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.11"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2"])
      s.add_development_dependency(%q<rubocop>, ["~> 0.35.0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.11"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<rspec>, ["~> 2"])
      s.add_dependency(%q<rubocop>, ["~> 0.35.0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.11"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<rspec>, ["~> 2"])
    s.add_dependency(%q<rubocop>, ["~> 0.35.0"])
  end
end
