# frozen_string_literal: true

RSpec.describe Socketry::Resolver::System, online: true do
  it_behaves_like "Socketry DNS resolver"
end
