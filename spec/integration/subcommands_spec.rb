# frozen_string_literal: true

RSpec.describe 'Subcommands' do
  context 'registry defined with module' do
    include_examples 'Subcommands', 'foo'
  end

  context 'registry defined with a block' do
    include_examples 'Subcommands', 'baz'
  end

  context 'CLI defined with builder and block (0 arity)' do
    include_examples 'Subcommands', 'faz'
  end
end
