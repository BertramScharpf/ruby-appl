#
#  lib/applfan.rb  --  ApplicationFan class
#

require "appl"


ApplicationFan = Class.new Application

class ApplicationFan

  AVAILCMDS = "Available commands (say -h after one for help)"
  NOCOMMAND = "No command given. Say -h for a list."
  UNKNWNCMD = "Unknown command: `%s'. Say -h for a list."

  class CommandError < StandardError ; end


  class <<self

    attr_accessor :commands

    def find_command name
      @commands.find { |c| c::NAME == name }
    end

    def help
      super do
        puts AVAILCMDS
        @commands.each { |c|
          puts "  %-10s  %s" % [ c::NAME, c::SUMMARY]
        }
        if block_given? then
          puts
          yield
        end
      end
    end

    private

    def inherited sub
      sub.instance_eval do
        @commands = []
        const_set :Command, (
          Class.new Application do
            define_singleton_method :inherited do |c|
              sub.commands.push c
              super c
            end
          end
        )
      end
      super
    end

  end

  def run
    c = @args.shift
    c or raise CommandError, NOCOMMAND
    cmd = self.class.find_command c
    cmd or raise CommandError, UNKNWNCMD % c
    a = @args.slice! 0, @args.length
    sub = cmd.new a
    sub.run
  end

end

