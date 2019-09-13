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
  spec.summary     = "A set of Rake tasks to bundle Rails apps for use on AWS Lambda"
  spec.description = "A set of Rake tasks to bundle Rails apps for use on AWS Lambda"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib,build_env}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rails'
end
