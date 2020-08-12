require 'cocoapods'

# module Pod
#   class Installer
#
#     class PodSourcePreparer
#       alias_method :old_prepare!, :prepare!
#       def prepare!
#         if @spec.flutter == nil || @spec.flutter == false
#           old_prepare!
#         else
#           flutter_run_prepare_command
#         end
#       end
#
#       def flutter_run_prepare_command
#         return unless @spec.prepare_command
#         UI.section(' > Running flutter prepare command', '', 1) do
#           Dir.chdir(path) do
#             begin
#               ENV.delete('CDPATH')
#               ENV['COCOAPODS_VERSION'] = Pod::VERSION
#               prepare_command = spec.prepare_command.strip_heredoc.chomp
#               full_command = "\nset -e\n" + prepare_command
#               bash!('-c', full_command)
#             ensure
#               ENV.delete('COCOAPODS_VERSION')
#             end
#           end
#         end
#       end
#
#     end
#   end
# end
