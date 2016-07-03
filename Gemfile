source "https://rubygems.org"

gemspec

group :development do
  gem "guard-rspec", require: false
  gem "pry", require: false
end

group :test do
  gem "rspec", "~> 3"
  gem "rubocop"
end

group :development, :test do
  gem "rake"
end
