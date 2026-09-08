# frozen_string_literal: true

require_relative "lib/benchmark/swap/version"

Gem::Specification.new do |spec|
  spec.name = "benchmark-swap"
  spec.version = Benchmark::Swap::VERSION
  spec.authors = ["Mehmet Emin INAC"]
  spec.email = ["mehmetemininac@gmail.com"]

  spec.summary = "Benchmark a second implementation of a method where it already runs."
  spec.description = <<~TEXT
    Write your alternative implementation next to the original one, with a
    _perf suffix on the name. Benchmark.swap runs your block twice, once with
    the original methods and once with the suffixed twins in their place, and
    compares the two. No need to lift the method out of its call chain first.
  TEXT
  spec.homepage = "https://github.com/meinac/benchmark-swap"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb"] + ["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "benchmark-ips", "~> 2.13"
end
