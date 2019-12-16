# frozen_string_literal: true

RSpec.describe 'Commands' do
  context 'registry defined with module' do
    include_examples 'Commands', 'foo'
  end

  context 'registry defined with a block' do
    include_examples 'Commands', 'baz'
  end

  context 'CLI defined with builder and block (0 arity)' do
    include_examples 'Commands', 'faz'
  end
end
