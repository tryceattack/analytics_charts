# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'analytics_charts/version'

Gem::Specification.new do |spec|
  spec.name          = "analytics_charts"
  spec.version       = AnalyticsCharts::VERSION
  spec.authors       = ["STEPHEN YU"]
  spec.email         = ["istephenyu@gmail.com"]
  spec.summary       = %q{Chart for analytics_charts}
  spec.description   = %q{Initially wrote code on top of gruff library. But eventually to do
    more fined-tuned data rendering and the need for more lightweight code, I branched out to
    this new library. Source for original code of gruff library.
  https://github.com/topfunky/gruff/}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_dependency 'rmagick'
end
