module LambdaLayerCake
  class RakeHelper
    include Rake::DSL

    #Files used to generate the gem layer
    INPUT_FILES = Rake::FileList.new(
      ['Gemfile', 'Gemfile.lock', 'system-packages.txt'].collect { |f| File.join(Rails.root, f) }
    )


    #Files used to generate the 
    APP_FILES = Rake::FileList.new(Dir['*'] - ['spec','test','log', 'tmp'])
    OUTPUT_DIR = File.expand_path(File.join(Rails.root,'.layer_cake/'))

    def layer_directory
      ".layer_cake/layer-#{input_hash}"
    end
    def layer_dependencies
      INPUT_FILES.existing
    end
    def layer_build
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

    def layer_task_definitions!
      desc "Builds a layer.zip with gems and libraries"
      task build_layer: ".layer_cake/layer.zip"
    
      desc "Build a layer for version #{input_hash}"
      directory ".layer_cake/layer-#{input_hash}"
      file ".layer_cake/layer-#{input_hash}" => layer_dependencies do
        layer_build
      end

      file ".layer_cake/layer-#{input_hash}.zip" => ".layer_cake/layer-#{input_hash}" do
        pwd = Dir.pwd
        begin
          Dir.chdir(outputs_dir)
          cmd = %W{zip -r #{File.join(working_dir, "layer-#{input_hash}.zip")} lib bundle}
          system(*cmd) or raise
        ensure
          Dir.chdir(pwd)
        end
      end

      desc "Build the current layer version and symlink it to the versioned zip"
      file ".layer_cake/layer.zip": ".layer_cake/layer-#{input_hash}.zip" do
        FileUtils.ln_s("layer-#{input_hash}.zip",".layer_cake/layer.zip", force: true)
      end    
    end

    def app_task_definitions!
      desc "Zip up Rails directory into an app"
      file ".layer_cake/app.zip": APP_FILES do
        FileUtils.mkdir_p(working_dir)

        cmd = %W{zip -r .layer_cake/app.zip}  + APP_FILES
        system(*cmd) or raise
        
        #Insert a symlink into the app.zip
        FileUtils.rm_r(working_dir("app/")) if(File.exists?(working_dir("app")))
        FileUtils.mkdir_p(working_dir("app/vendor"))
        FileUtils.ln_s("/tmp", working_dir("app/tmp"))
        FileUtils.ln_s("/opt/bundle", working_dir("app/vendor/bundle"), force: true)
        Dir.chdir(working_dir("app")) do
          system(*((%W{zip --symlinks -r} << working_dir("app.zip")) + Dir["*"])) or raise
        end
      end    
    end

    def version_task_definitions!
      desc "Output the version hash for the current input files (Gemfile, Gemfile.lock, system-packages.txt)"
      task :version do
        $stdout.write input_hash
      end    
    end

    def clean_task_definitions!
      desc "Clean out intermediate files"
      task :clean do
        FileUtils.rm_r(working_dir) if File.exists?(working_dir)
      end
    end

    private
    # Some helper methods
    def input_hash
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
          OUTPUT_DIR,
          path_suffix
        )
      )
    end
  end
end