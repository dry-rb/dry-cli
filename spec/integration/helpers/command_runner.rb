require 'english'

class CommandRunner
  class MultipleExecutionError < StandardError
  end

  attr_reader :cmd, :out, :code, :error, :has_run

  def initialize(cmd, run_now: false)
    @cmd     = cmd
    @has_run = false

    execute! if run_now
  end

  def execute!
    raise MultipleExecutionError, "Command #{cmd} has already been executed by the runner" if has_run?

    begin
      @out = `#{cmd}`
    rescue StandardError => e
      @error = e.class
    ensure
      @code    = $CHILD_STATUS.exitstatus
      @has_run = true
    end
  end

  def has_run?
    has_run
  end
end
