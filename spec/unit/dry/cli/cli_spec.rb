# frozen_string_literal: true

RSpec.describe 'CLI' do
  context 'with registry' do
    include_examples 'Commands', WithRegistry
    include_examples 'Rendering', WithRegistry
    include_examples 'Subcommands', WithRegistry
    include_examples 'Third-party gems', WithRegistry
  end

  context 'with block' do
    include_examples 'Commands', WithBlock
    include_examples 'Rendering', WithBlock
    include_examples 'Subcommands', WithBlock
    include_examples 'Third-party gems', WithBlock
  end

  context 'with zero arity block' do
    include_examples 'Commands', WithZeroArityBlock
    include_examples 'Rendering', WithZeroArityBlock
    include_examples 'Subcommands', WithZeroArityBlock
    include_examples 'Third-party gems', WithZeroArityBlock
  end
end
