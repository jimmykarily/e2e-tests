require 'rspec/core/rake_task'

desc "Run tests"
RSpec::Core::RakeTask.new('test') do |t|
  t.rspec_opts = ["-I.","--format documentation","--color"]
  t.pattern = ['spec/**/*.rb']
end
