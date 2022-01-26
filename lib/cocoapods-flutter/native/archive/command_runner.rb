require 'cocoapods'

class CommandRunner

  def CommandRunner.run(*args)
    command = args.join ' '
    Pod::UserInterface.info "Running #{command}..."
    stdin, stdout_stderr, wait_thr = Open3.popen2e(*args)
    Thread.new do
      stdout_stderr.each {|l| puts l }
    end

    exit_status = wait_thr.value
    if exit_status.success?
      puts stdout_stderr.gets
    else
      puts stdout_stderr.gets
    end
    stdin.close
    stdout_stderr.close
    return exit_status.success?
  end
end