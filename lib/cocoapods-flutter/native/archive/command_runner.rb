require 'cocoapods'

class CommandRunner

  def CommandRunner.run(*args)
    command = args.join ' '
    Pod::UserInterface.info "Running #{command}..."
    stdin, stdout, stderr, wait_thr = Open3.popen3(*args)
    exit_status = wait_thr.value
    if exit_status.success?
      puts stdout.gets
    else
      puts stderr.gets
    end
    return exit_status.success?
  end
end