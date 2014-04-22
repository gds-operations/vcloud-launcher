require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'gem_publisher'

task :default => [:spec,:features]

RSpec::Core::RakeTask.new(:spec) do |task|
  # Set a bogus Fog credential, otherwise it's possible for the unit
  # tests to accidentially run (and succeed against!) an actual 
  # environment, if Fog connection is not stubbed correctly.
  ENV['FOG_CREDENTIAL'] = 'random_nonsense_owiejfoweijf'
  task.pattern = FileList['spec/vcloud/**/*_spec.rb']
end

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty --no-source"
  t.fork = false
end

RSpec::Core::RakeTask.new('integration:quick') do |t|
  t.rspec_opts = %w(--tag ~take_too_long)
  t.pattern = FileList['spec/integration/**/*_spec.rb']
end

RSpec::Core::RakeTask.new('integration:all') do |t|
  t.pattern = FileList['spec/integration/**/*_spec.rb']
end

task :publish_gem do |t|
  gem = GemPublisher.publish_if_updated("vcloud-launcher.gemspec", :rubygems)
  puts "Published #{gem}" if gem
end
