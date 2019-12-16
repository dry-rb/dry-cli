# frozen_string_literal: true

RSpec.describe 'Rendering' do
  context 'registry defined with module' do
    include_examples 'Rendering', 'foo'
  end

  context 'registry defined with a block' do
    include_examples 'Rendering', 'baz'
  end

  context 'CLI defined with builder and block (0 arity)' do
    include_examples 'Rendering', 'faz'
  end
end
