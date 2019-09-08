require 'digest'
require 'fileutils'

require 'rake/packagetask'

namespace :layer_cake do
  desc 'Clean the build directories'
  task :clean do
    LambdaLayerCake.clean!
  end

  #Files used to generate the gem layer
  INPUT_FILES = Rake::FileList.new(
    ['Gemfile', 'Gemfile.lock', 'system-packages.txt'].collect { |f| File.join(Rails.root, f) }
  )
  #Files used to generate the 
  APP_FILES = Rake::FileList.new(Dir['*'] - ['spec','test','log', 'tmp'])
  OUTPUT_DIR = '.layer_cake'

  # Some helper methods
  def self.input_hash
    @input_hash ||= begin
      hash = Digest::SHA1.hexdigest(INPUT_FILES.existing.collect do |f|
        File.read(f)
      end.join("\x1C"))
      hash[0..7]
    end
  end

  def inputs_dir
    working_dir("layer_inputs")
  end

  def outputs_dir
    working_dir("layer-#{input_hash}")
  end

  def working_dir(path_suffix = "")
    File.expand_path(
      File.join(
        Rails.root,
        '.layer_cake/',
        path_suffix
      )
    )
  end

  desc "Output the version hash for the current input files (Gemfile, Gemfile.lock, system-packages.txt)"
  task :version do
    $stdout.write input_hash
  end

  desc "Builds a layer.zip with gems and libraries"
  task build_layer: '.layer_cake/layer.zip'

  desc "Build a layer for version #{input_hash}"
  directory ".layer_cake/layer-#{input_hash}"
  file ".layer_cake/layer-#{input_hash}": INPUT_FILES.existing do
    FileUtils.mkdir_p(inputs_dir)
    FileUtils.cp(INPUT_FILES.existing, inputs_dir)

    cmd = %W{docker run --rm
      -v #{inputs_dir}:/tmp/inputs 
      -v #{outputs_dir}:/tmp/outputs 
      -v #{File.expand_path(__dir__ + "/../../build_env")}:/var/task 
      lambci/lambda:build-ruby2.5 ruby build_ruby.rb}
    STDERR.puts("Excuting cmd: #{cmd.join(' ')}")
    system(*cmd) or raise
  end
  
  file ".layer_cake/layer-#{input_hash}.zip": ".layer_cake/layer-#{input_hash}" do
    pwd = Dir.pwd
    begin
      Dir.chdir(outputs_dir)
      cmd = %W{zip -r #{File.join(working_dir, "layer-#{input_hash}.zip")} lib ruby}
      system(*cmd) or raise
    ensure
      Dir.chdir(pwd)
    end
  end
  
  desc "Build the current layer version and symlink it to the versioned zip"
  file ".layer_cake/layer.zip": ".layer_cake/layer-#{input_hash}.zip" do
    FileUtils.ln_s("layer-#{input_hash}.zip",".layer_cake/layer.zip", force: true)
  end

  desc "Zip up Rails directory into an app"
  file ".layer_cake/app.zip": APP_FILES do
    cmd = %W{zip -r .layer_cake/app.zip} + APP_FILES
    system(*cmd) or raise
  end
end