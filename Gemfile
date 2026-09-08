# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.13"

# RuboCop pulls in gems that need a newer ruby than this gem supports, so the
# spec matrix installs without this group.
group :lint do
  gem "rubocop", "~> 1.90"
  gem "rubocop-rspec", "~> 3.0"
end
