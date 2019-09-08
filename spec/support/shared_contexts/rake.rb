# spec/support/shared_contexts/rake.rb
require "rake"

shared_context "rake" do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.description }
  let(:task_path) { "tasks/#{task_name.split(":").first}" }
  subject         { rake[task_name] }

  def loaded_files_excluding_current_rake_file
    $".reject {|file| file == Rails.root.join("#{task_path}").to_s }
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(task_path)

    Rake::Task.define_task(:environment)
  end
end