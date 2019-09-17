require 'digest'
require 'fileutils'

require 'rake/packagetask'

require 'lambda_layer_cake/rake_helper'

namespace :layer_cake do
  LambdaLayerCake::RakeHelper.new.tap do |rh| 
    rh.clean_task_definitions!
    rh.version_task_definitions!
    rh.layer_task_definitions!
    rh.app_task_definitions!
  end
end