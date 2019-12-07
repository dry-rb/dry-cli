# frozen_string_literal: true

RSpec.describe 'Dry::CLI::VERSION' do
  it 'exposes version' do
    expect(Dry::CLI::VERSION).to eq('0.3.1')
  end
end
