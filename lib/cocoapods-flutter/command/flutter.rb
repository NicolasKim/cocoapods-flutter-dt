require 'cocoapods-flutter/command/flutter/archive'

module Pod
  class Command
    class Flutter < Command
      self.summary = ''

      self.description = <<-DESC
        flutter command line tools
      DESC

      def initialize(argv)
        @help = argv.flag?('help')
        super
      end

      def validate!
        super
        banner! if @help
      end
    end
  end
end
