# TODOs:
# * Better application layout (with flash configured). Bootstrap by default?
# * Better ASCII art when done



# -- Set consistent Ruby version -----

create_file ".ruby-version", RUBY_VERSION
insert_into_file "Gemfile", %|ruby File.read(File.expand_path "../.ruby-version", __FILE__)|,
  after: "source 'https://rubygems.org'\n"


# -- Configure Gemfile -----

%w( byebug web-console ).each do |name|
  # Remove Gems
  gsub_file "Gemfile", /^\s*gem\s+["']#{name}["'].*\n/, ''
end

%w(
    bootstrap_form devise figaro pg pry-rails quiet_assets slim-rails
    twitter-bootstrap-rails
).each { |name| gem name }

gem_group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'factory_girl_rails'
end

gem_group :test do
  gem 'simplecov'
  gem 'zonebie'
end

gem_group :production do
  gem 'rails_12factor'
  gem 'puma'
  gem 'rollbar'
end


# -- Run generators, &c -----

after_bundle do
  run "spring stop" # the next generators may hang otherwise

  # Bootstrap
  generate "bootstrap:install static"
  remove_file "app/views/layouts/application.html.erb"
  generate "bootstrap:layout"

  # Figaro
  run "figaro install"

  # Rollbar
  generate "rollbar"

  # Devise
  generate "devise:install"
  generate "devise", "User"
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }'

  rake "db:migrate"

  # Initialize the git repo
  %w( .DS_Store .env ).each do |ignored|
    append_to_file ".gitignore", ignored
  end
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }

  say "You're all set!", Thor::Shell::Color::GREEN
end
