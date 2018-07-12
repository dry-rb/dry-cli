$LOAD_PATH.unshift "lib"
require "hanami/utils"
require "hanami/devtools/unit"
require "hanami/cli"
require_relative "./support/rspec"
Hanami::Utils.require!("spec/support/**/*.rb")
