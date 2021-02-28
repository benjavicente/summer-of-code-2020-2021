# frozen_string_literal: true

require 'haml'
require 'sassc'

Dir.mkdir('dist') unless Dir.exist?('dist')

def make_html(out = 'dist')
  template = File.read('page/index.haml')
  haml_engine = Haml::Engine.new(template)
  html_output = haml_engine.render
  File.write("#{out}/index.html", html_output)
end

def make_css(out = 'dist')
  sass = File.read('page/style.scss')
  css_output = SassC::Engine.new(sass, syntax: :scss).render
  File.write("#{out}/style.css", css_output)
end

def make_safe
  begin
    make_css
  rescue SassC::SyntaxError => e
    puts 'error in Sass:'
    puts e
  end
  make_html
end

def watch_mode
  puts 'in watch mode, use ^C to exit'
  require 'listen'
  make_safe

  listener = Listen.to('page/') do |_modified, _added, _removed|
    puts 'changed'
    make_safe
  end

  begin
    listener.start
    sleep
  rescue Interrupt => _e
    puts "\nexiting"
  end
end

def gh_page
  `git worktree add -B gh-pages -f build`
  Dir.chdir('build') do
    `git update-ref -d HEAD; git rm . -rf` # Complete branch reset
  end
  make_html('build')
  make_css('build')
  Dir.chdir('build') do
    `git add .; git commit -m "update"`
  end
  `git worktree remove build -f`
end

if ARGV.include?('-w')
  watch_mode
elsif ARGV.include?('-gh')
  gh_page
else
  make_safe
end
