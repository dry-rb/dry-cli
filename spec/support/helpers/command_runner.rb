class CommandRunner
  class MultipleExecutionError < StandardError
  end

  attr_reader :cmd, :out, :code, :error, :has_run

  def initialize(cmd, run_now: false)
    @cmd     = cmd
    @has_run = false

    execute! if run_now
  end

  # rubocop:disable Style/SpecialGlobalVars
  def execute!
    raise MultipleExecutionError, "Command #{cmd} has already been executed by the runner" if has_run?

    begin
      @out = `#{cmd}`
    rescue StandardError => e
      @error = e.class
    ensure
      @code    = $?.exitstatus
      @has_run = true
    end
  end
  # rubocop:enable Style/SpecialGlobalVars

  def has_run?
    has_run
  end
end
