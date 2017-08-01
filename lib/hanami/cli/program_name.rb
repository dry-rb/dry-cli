module Hanami
  class CLI
    module ProgramName
      SEPARATOR = " ".freeze

      def self.call(names = [], program_name: $PROGRAM_NAME)
        [File.basename(program_name), names].flatten.join(SEPARATOR)
      end
    end
  end
end
