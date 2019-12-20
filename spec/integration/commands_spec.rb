# frozen_string_literal: true

RSpec.describe 'Commands' do
  context 'with extra params' do
    context 'when there is a required argument' do
      context 'and there are options' do
        it 'parses both separately' do
          output = `foo variadic with-mandatory-and-options uno -- due tre --blah`
          expect(output).to eq("first: uno\nurl: \nmethod: \nUnused Arguments: due, tre, --blah\n") # rubocop:disable Metrics/LineLength
        end
      end
    end
  end
end
