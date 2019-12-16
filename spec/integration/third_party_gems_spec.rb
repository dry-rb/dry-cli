# frozen_string_literal: true

RSpec.describe 'Third-party gems' do
  context 'registry defined with module' do
    include_examples 'Third-party gems', 'foo'
  end

  context 'registry defined with a block' do
    include_examples 'Third-party gems', 'baz'
  end

  context 'CLI defined with builder and block (0 arity)' do
    include_examples 'Third-party gems', 'faz'
  end
end
