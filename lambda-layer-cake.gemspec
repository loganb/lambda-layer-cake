$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "lambda_layer_cake/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "lambda-layer-cake"
  spec.version     = LambdaLayerCake::VERSION
  spec.authors     = ["Logan Bowers"]
  spec.email       = ["logan@datacurrent.com"]
  spec.homepage    = "http://github.com/loganb/lambda-layer-cake"
  spec.summary     = "Summary of LambdaLayerCake."
  spec.description = "Description of LambdaLayerCake."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.0"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rails'
end
