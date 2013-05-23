#
#  appl.rb  --  Application class
#


class Application

  STOPOPT = "stop option processing"
  UNKNOWN = "Unknown option"
  UNPROCA = "Warning: unprocessed arguments"

  class OptionError < StandardError ; end
  class Done        < Exception     ; end

  def initialize args = nil
    @args = args||$*
    self.class.each_option { |opt,desc,arg,dfl,act|
      begin
        send act, dfl if dfl
      rescue NoMethodError
        raise OptionError, "Option action `#{act}' is not defined."
      end
    }
    while @args.first =~ /\A-/ do
      opt = $'
      @args.shift
      if opt =~ /\A-/ then
        break if $'.empty?
        act = self.class.option_act @args, $', nil
        send *act
      else
        until opt.empty? do
          c = opt.slice! 0, 1
          act = self.class.option_act @args, c, opt
          send *act
        end
      end
    end
  end

  def help
    c = self.class
    puts c.version
    puts
    c.show_options
    puts
    yield if block_given?
    puts c::DESCRIPTION
    raise Done
  end

  def version
    self.class.show_version
    raise Done
  end

  VERSION = "0"
  NAME    = "appl"
  SUMMARY = "Dummy application"
  DESCRIPTION = <<-EOT
This base class does nothing by default.
  EOT

  def run
  end

  def execute
    run
    if @args.any? then
      u = @args.join " "
      puts "#{self.class::UNPROCA}: #{u}"
    end
    0
  rescue SignalException
    raise if @debug
    self.class.show_message $!.inspect
    128 + ($!.signo||2)    # Ruby 1.8 returns signo +nil+; assume SIGINT
  rescue
    raise if @debug
    self.class.show_message "Error: #$!", "(#{$!.class})"
    $!.to_i rescue 1
  end

  class <<self

    def run args = nil
      e = execute args
      exit e
    end

    def version
      if self::VERSION =~ %r/\s/ then
        self::VERSION
      else
        "#{self::NAME} #{self::VERSION}  --  #{self::SUMMARY}"
      end
    end

    private

    def execute args = nil
      i = new args
      i.execute
    rescue Done
      0
    rescue OptionError
      show_message $!
      127
    end

    def inherited sub
      sub.instance_eval { @options, @aliases = {}, {} }
    end

    def attr_bang *syms
      syms.each { |sym|
        define_method :"#{sym}!" do
          instance_variable_set :"@#{sym}", true
        end
      }
      nil
    end

    public

    def define_option opt, *param
      delete_option opt
      act = param.shift
      desc = param.pop
      arg = param.shift
      if arg then
        if param.empty? then
          arg, dfl = arg.split /:/, 2
          if dfl =~ /\A:/ then
            dfl = $'.to_sym
          end
        else
          dfl = param.shift
        end
      end
      d = param.map { |x| "#{x}#$/" }.join
      desc.insert 0, d
      @options[ opt.to_s] = [ desc, arg, dfl, act]
      nil
    end
    alias def_option define_option

    def alias_option orig, opt
      unalias_option opt
      @aliases[ opt.to_s] = orig.to_s
      nil
    end

    def delete_option opt
      self < Application or return
      superclass.delete_option opt
      @options.delete opt
      @aliases.reject! { |k,v| v == opt }
      nil
    end

    def unalias_option opt
      self < Application or return
      superclass.unalias_option opt
      @aliases.delete opt
      nil
    end

    def find_option_act opt
      self < Application or return
      @options[ opt] || @options[ @aliases[ opt]] ||
        (superclass.find_option_act opt)
    end

    def all_options
      if self < Application then
        r = superclass.all_options
        r.update @options
      else
        {}
      end
    end

    def each_option
      o = all_options.sort_by { |k,v| k.swapcase }
      o.each { |opt,(desc,arg,dfl,act)|
        case dfl
          when Symbol then dfl = const_get dfl
        end
        yield opt, desc, arg, dfl, act
      }
    end

    def all_aliases
      if self < Application then
        r = superclass.all_aliases
        r.update @aliases
      else
        {}
      end
    end

    def option_act args, opt, rest
      dada = find_option_act opt
      dada or raise OptionError, "#{self::UNKNOWN}: `#{opt}'."
      desc, arg, dfl, act = *dada
      r = [ act]
      if arg then
        p = rest.slice! 0, rest.length if rest and not rest.empty?
        r.push p||args.shift
      end
      r
    end

    def options_desc &block
      a = Hash.new do |h,k| h[ k] = [] end
      all_aliases.each { |k,v|
        a[ v].push k
      }
      each_option { |opt,desc,arg,dfl,|
        yield opt, arg, dfl, desc
        a[ opt].sort.each { |l|
          yield l, nil, nil, nil
        }
      }
      yield "", nil, nil, self::STOPOPT
    end

    def show_options
      options_desc do |opt,arg,dfl,desc|
        opt = opt.length == 1 ? "-#{opt}" : "--#{opt}"
        arg &&= "#{arg}"
        dfl &&= "[#{dfl}]"
        arg << dfl if arg && dfl
        puts "  %-10s  %-12s  %s" % [ opt, arg, desc]
      end
    end

    def show_version
      puts version
      puts COPYRIGHT if const_defined? :COPYRIGHT
      puts LICENSE   if const_defined? :LICENSE
      a = []
      a.push   AUTHOR  if const_defined? :AUTHOR
      a.concat AUTHORS if const_defined? :AUTHORS
      a.flatten!
      if a.any? then
        a.uniq!
        j = a.join ", "
        puts j
      end
    end

    def show_message msg, extra = nil
      if $stderr.tty? then
        msg = "\e[31;1m#{msg}\e[m"
        if extra then
          extra = "\e[31m#{extra}\e[m"
        end
      end
      if extra then
        msg = [ msg, extra].join " "
      end
      $stderr.puts msg
    end

  end

end

