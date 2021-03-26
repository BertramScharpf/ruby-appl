#
#  lib/applfan.rb  --  ApplicationFan class
#

require "appl"


class ApplicationFan < Application

  AVAILCMDS = "Available commands (say -h after one for help)"
  NOCOMMAND = "No command given. Say -h for a list."
  UNKNWNCMD = "Unknown command: `%s'. Say -h for a list."

  W_CMDS = 16

  class CommandError < StandardError ; end

  class <<self

    attr_accessor :commands

    def find_command name
      @commands.find { |c| c::NAME == name or c::ALIASES.include? name }
    end


    def help
      super do
        if block_given? then
          yield
          puts
        end
        puts self::AVAILCMDS
        puts
        @commands.each { |c|
          puts "  %-*s  %s" % [ self::W_CMDS, c.all_names, c::SUMMARY]
        }
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
            define_singleton_method :root do
              sub.root
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
    sub = cmd.new c, (@args.slice! 0, @args.length)
    yield sub if block_given?
    sub.execute
  end

end

