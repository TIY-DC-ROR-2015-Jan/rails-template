# TODOs:
# * Better application layout (with flash configured). Bootstrap by default?
# * Better ASCII art when done

def remove_gem name
  gsub_file "Gemfile", /^\s*gem\s+["']#{name}["'].*\n/, ''
end

remove_gem 'turbolinks'
gsub_file "app/assets/javascripts/application.js", /^.*turbolinks.*$/, ''

remove_gem 'byebug'
remove_gem 'web-console'

gem 'devise'
gem 'figaro'
gem 'activesupport'
gem 'slim-rails'

%w( httparty ).each do |optional|
  if yes? "Install #{optional}? (y/n)"
    gem optional
  end
end

gem_group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'quiet_assets'
end

gem_group :test do
  gem 'factory_girl_rails'
  gem 'simplecov'
  gem 'zonebie'
end


def configure_rspec
  run "rm -rf test"
  generate "rspec:install"

  # Ew. This is real gross.
  uncomment_lines "spec/rails_helper.rb", /Dir\[Rails.root.join\('spec\/support/

  %w( models controllers support ).each { |f| empty_directory "spec/#{f}" }

  file "spec/support/focus.rb", <<-CODE
RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
  CODE

  file "spec/support/devise.rb", <<-CODE
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller

  module ExtraDeviseTestHelpers
    def login user
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
    end
  end
  config.include ExtraDeviseTestHelpers
end
  CODE

  file "spec/support/json.rb", <<-CODE
RSpec.configure do |config|
  module JSONHelpers
    def json
      if response.body.empty?
        raise "Empty body; did you enable `render_views`?"
      else
        JSON.parse response.body
      end
    end
  end
  config.include JSONHelpers
end
  CODE
end


def configure_devise
  # TODO: add `before_action :authenticate_user!`?
  generate "devise:install"
  generate "devise", "User"
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }'
end


def initialize_git_repo
  %w( .DS_Store .env ).each do |ignored|
    append_to_file ".gitignore", ignored
  end

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end


after_bundle do
  run "spring stop" # the next generators may hang otherwise
  run "figaro install"
  configure_rspec
  configure_devise
  rake "db:migrate"
  initialize_git_repo

  say "You're all set!", Thor::Shell::Color::GREEN
end
