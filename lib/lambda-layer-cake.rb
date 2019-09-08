module LambdaLayerCake
  require 'lambda_layer_cake/railtie' if defined?(Rails)

  class Builder
    attr :version

    def initialize(version)
      @version = version
    end

    def clean!
      FileUtils.rm_r(outputs_dir!)
    end

    def build_layer!
      FileUtils.cp(%w{Gemfile Gemfile.lock system-packages.txt}.select {|f| File.exist?(f) }, inputs_dir!)

      cmd = %W{docker run --rm
        -v #{inputs_dir!}:/tmp/inputs 
        -v #{outputs_dir!}:/tmp/outputs 
        -v #{tools_dir}:/var/task 
        lambci/lambda:build-ruby2.5 ruby build_ruby.rb}
      STDERR.puts("Excuting cmd: #{cmd.join(' ')}")
      system(*cmd) or raise
    end

    def zip_layer! 
      pwd = Dir.pwd
      begin
        Dir.chdir(outputs_dir!)
        cmd = *%W{zip -r #{File.join(build_dir!, "layer-#{version}.zip")} lib ruby}
        system(*cmd) or raise
      ensure
        Dir.chdir(pwd)
      end
    end

    def build_rails!

    end

    private

    def inputs_dir!
      working_dir!("layer_inputs")
    end

    def outputs_dir!
      working_dir!("layer-#{version}")
    end

    def working_dir!(path_suffix = "")
      File.expand_path(
        File.join(
          Rails.root,
          '.layer_cake/',
          path_suffix
        )
      ).tap { |d| FileUtils.mkdir_p(d) }
    end

    def tools_dir
      File.expand_path(__dir__ + "/../build_env") # Never needs to be created
    end

    def build_dir!
      working_dir!
    end
  end
end
