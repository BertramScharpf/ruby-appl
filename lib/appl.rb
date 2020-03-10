#
#  appl.rb  --  Application class
#


class Application

  APPL_VERSION = "1.7".freeze

  OPTIONS_ENV = nil

  STOPOPT = "stop option processing"
  UNKNOWN = "Unknown option: `%s'."
  UNPROCA = "Warning: unprocessed arguments: %s"

  class OptionError < StandardError ; end
  class Done        < Exception     ; end

  def initialize args = nil
    @args = args||self.class.cmdline_arguments
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
        break if !$' or $'.empty?
        opt = $'
        if opt =~ /^=/ then opt = $` ; @args.unshift $' end
        act = self.class.option_act @args, opt, nil
        send *act
      else
        until not opt or opt.empty? do
          c = opt.slice! 0, 1
          if opt =~ /^=/ then opt = nil ; @args.unshift $' end
          act = self.class.option_act @args, c, opt
          send *act
        end
      end
    end
  end

  def help
    self.class.help
    raise Done
  end

  def version
    self.class.version
    raise Done
  end

  def run
  end

  def execute
    run
    if @args.any? then
      puts self.class::UNPROCA % (@args.join " ")
    end
    0
  rescue SignalException
    raise if @debug
    self.class.show_message $!.inspect
    128 + $!.signo
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
      sub.name or return
      o, a = @options.dup.to_h, @aliases.dup.to_h
      sub.instance_eval { @options, @aliases = o, a }
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
      @aliases.reject! { |k,v| v == opt }
      @options.delete opt
      nil
    end

    def unalias_option opt
      @aliases.delete opt
      nil
    end

    protected

    def find_option_act opt
      @options[ opt] || @options[ @aliases[ opt]]
    end

    def options_desc &block
      a = Hash.new do |h,k| h[ k] = [] end
      @aliases.each { |k,v|
        a[ v].push k
      }
      each_option { |opt,desc,arg,dfl,|
        yield opt, arg, dfl, desc
        a[ opt].each { |l|
          yield l, nil, nil, nil
        }
      }
      yield "", nil, nil, self::STOPOPT
    end

    public

    def each_option
      @options.each { |opt,(desc,arg,dfl,act)|
        case dfl
          when Symbol then dfl = const_get dfl
        end
        yield opt, desc, arg, dfl, act
      }
    end

    def option_act args, opt, rest
      dada = find_option_act opt
      dada or raise OptionError, self::UNKNOWN % opt
      desc, arg, dfl, act = *dada
      r = [ act]
      if arg then
        p = rest.slice! 0, rest.length if rest and not rest.empty?
        r.push p||args.shift
      end
      r
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

    def help
      puts "#{self::NAME}  --  #{self::SUMMARY}"
      puts
      puts self::DESCRIPTION
      puts
      show_options
      if block_given? then
        puts
        yield
      end
    end

    def version
      puts "#{self::NAME} #{self::VERSION}  --  #{self::SUMMARY}"
      puts self::COPYRIGHT if const_defined? :COPYRIGHT
      puts "License: #{self::LICENSE}" if const_defined? :LICENSE
      a = []
      a.push   self::AUTHOR  if const_defined? :AUTHOR
      a.concat self::AUTHORS if const_defined? :AUTHORS
      if a.any? then
        a.flatten!
        a.uniq!
        j = a.join ", "
        h = a.length == 1 ? "Author" : "Authors"
        puts "#{h}: #{j}"
      end
      puts "Ruby version: #{RUBY_VERSION}"
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

    def cmdline_arguments
      r = []
      oe = self::OPTIONS_ENV
      eo = ENV[ oe] if oe
      if eo then
        eo.scan /"((?:\\.|[^"])*")|[^" \t]+/ do
          r.push $1 ? (eval $1) : $&
        end
      end
      r.concat $*
      $*.clear
      r
    end

  end

end

