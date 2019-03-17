# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "guard-rspec", require: false
  gem "pry", require: false
end

group :test do
  gem "coveralls", require: false
  gem "rspec", "~> 3.7", require: false
  gem "rubocop", "= 0.65.0", require: false
end

group :development, :test do
  gem "rake"
end
