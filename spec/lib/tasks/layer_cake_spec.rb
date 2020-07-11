require 'open3'
require 'zip'

describe "tasks" do
  around(:each) do |example|
    Bundler.with_clean_env do
      old_dir = Dir.pwd
      Dir.chdir(DUMMY_RAILS_DIR)

      result, status = Open3.capture2({"BUNDLE_GEMFILE" => 'Gemfile.test'}, 'rake layer_cake:clean')

      example.run
      Dir.chdir(Dir.pwd)
    end
  end
  
  describe "layer_cake:version" do
    # include_context "rake"
    
    it "outputs a version hash" do
      result, status = Open3.capture2({"BUNDLE_GEMFILE" => 'Gemfile.test'}, 'rake layer_cake:version')
      expect(result).to match(/[0-9a-f]{8}/)
    end
  end

  describe "layer_cake:ruby_version" do
    it "outputs a the ruby version" do
      result, status = Open3.capture2({"BUNDLE_GEMFILE" => 'Gemfile.test'}, 'rake layer_cake:ruby_version')
      expect(result).to match(/\d+\.\d+\.\d+/)
    end
  end

  describe ".layer_cake/layer.zip" do
    it "creates a layer.zip" do
      result, status = Open3.capture2({"BUNDLE_GEMFILE" => 'Gemfile.test'}, 'rake .layer_cake/layer.zip')
      expect(File.exists?(".layer_cake/layer.zip")).to be true
    end
  end

  describe ".layer_cake/app.zip" do
    it "creates an app.zip" do
      result, status = Open3.capture2({"BUNDLE_GEMFILE" => 'Gemfile.test'}, 'rake .layer_cake/app.zip')
      expect(File.exists?(".layer_cake/app.zip")).to be true
    end

    it "symlinks tmp & vendor/bundle directory that is a symlink" do
      result, status = Open3.capture2({"BUNDLE_GEMFILE" => 'Gemfile.test'}, 'rake .layer_cake/app.zip')

      zf = Zip::File.new('.layer_cake/app.zip')

      ['tmp', 'vendor/bundle'].each do |file|
        tmpdir = zf.entries.find { |e| e.name == file }
        expect(tmpdir).not_to be_nil, "expected to find file #{file}"
        expect(tmpdir.ftype).to be(:symlink)
      end
    end
  end
end