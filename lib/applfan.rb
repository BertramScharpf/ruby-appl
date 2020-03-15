#
#  lib/applfan.rb  --  ApplicationFan class
#

require "appl"


ApplicationFan = Class.new Application

class ApplicationFan

  AVAILCMDS = "Available commands (say -h after one for help)"
  NOCOMMAND = "No command given. Say -h for a list."
  UNKNWNCMD = "Unknown command: `%s'. Say -h for a list."

  W_CMDS = 16

  class CommandError < StandardError ; end

  class <<self

    attr_accessor :commands

    def find_command name
      @commands.find { |c| c::NAME == name }
    end


    def help
      super do
        puts self::AVAILCMDS
        puts
        @commands.each { |c|
          puts "  %-*s  %s" % [ self::W_CMDS, c::NAME, c::SUMMARY]
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
            define_singleton_method :applname do
              "#{sub::NAME} #{self::NAME}"
            end
          end
        )
      end
      super
    end

  end

  def run
    c = @args.shift
    c or raise CommandError, self.class::NOCOMMAND
    cmd = self.class.find_command c
    cmd or raise CommandError, self.class::UNKNWNCMD % c
    (cmd.new @args.slice! 0, @args.length).tap { |sub|
      yield sub if block_given?
      sub.run
    }
  end

end

