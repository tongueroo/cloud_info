require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'gemspec'

desc "Generate gemspec"
task :gemspec do
  File.open("#{Dir.pwd}/#{GEM_NAME}.gemspec", 'w') do |f|
    f.write(GEM_SPEC.to_ruby)
  end
end

desc "Install gem"
task :install do
  Rake::Task['gem'].invoke
  $stdout.puts "Use sudo?"
  sudo = ($stdin.gets.downcase[0..0] == 'y') ? 'sudo ' : ''
  $stdout.puts "Installing gem..."
  `#{sudo} gem uninstall #{GEM_NAME} -x`
  `#{sudo} gem install pkg/#{GEM_NAME}*.gem`
  `rm -Rf pkg`
end

desc "Package gem"
Rake::GemPackageTask.new(GEM_SPEC) do |pkg|
  pkg.gem_spec = GEM_SPEC
end

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = FileList["spec/**/*_spec.rb"]
end

task :default => :spec do
end

# You can delete this after you use it
desc "Rename project"
task :rename do
  name = ENV['NAME'] || File.basename(Dir.pwd)
  class_name = name.split('_').collect{|x| x.capitalize}.join("")
  begin
    dir = Dir['**/gem_template*']
    from = dir.pop
    if from
      rb = from.include?('.rb')
      to = File.dirname(from) + "/#{name}#{'.rb' if rb}"
      FileUtils.mv(from, to)
    end
  end while dir.length > 0
  Dir["**/*"].each do |path|
    next if path.include?('Rakefile')
    if File.file?(path)
      `sed -i "" 's/gem_template/#{name}/g' #{path}`
      `sed -i "" 's/GemTemplate/#{class_name}/g' #{path}`
    end
  end
end