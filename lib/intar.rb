#
#  intar.rb  --  Interactive Ruby evaluation
#


=begin rdoc

This could be opened not only by the Intar executable but also
everywhere inside your Ruby program.

= Example 1

  require "intar"

  Intar.prompt = "str(%(length)i):%03n%> "
  a = "hello"
  Intar.run a


= Example 2

  require "intar"

  class C
  end

  class IntarC < Intar
    @show     = 3
    @prompt   = "%(33 1)c%t%c%> "
    @histfile = ".intarc_history"

    class <<self
      def open
        super C.new
      end
    end
  end

  IntarC.open do |ia| ia.run end

=end


require "readline"
require "supplement"
require "supplement/terminal"


class Object
  def empty_binding
    binding
  end
end

class Intar

  class History

    IND = "  "
    IND_RE = /^#{IND}/

    def initialize filename
      @filename = filename
      return unless @filename
      h = "~" unless @filename[ File::SEPARATOR]
      @filename = File.expand_path @filename, h
      File.exists? @filename and File.open @filename do |h|
        c = []
        h.each { |l|
          case l
            when IND_RE then c.push $'
            else             push c.join.chomp ; c.clear
          end
        }
        push c.join.chomp
      end
      @num = Readline::HISTORY.length
    end

    def finish max
      return unless @filename
      @num.times { Readline::HISTORY.shift }
      File.open @filename, "a" do |h|
        a = []
        while (c = Readline::HISTORY.shift) do a.push c end
        if a.any? then
          h.puts "# #{Time.now}"
          a.each { |c|
            c.each_line { |l| h.puts IND + l }
            h.puts "-"
          }
          i = a.length
          h.puts "# #{i} #{entry_str i} added"
        end
      end
      n = File.open @filename do |h|
        h.inject 0 do |i,l| i += 1 if l =~ IND_RE ; i end
      end
      i = max - n
      if i < 0 then
        f = nil
        File.open @filename do |h|
          h.each_line { |l|
            f.push l if f
            case l
              when IND_RE then i += 1
              else             f ||= [] if i >= 0
            end
          }
        end
        f and File.open @filename, "w" do |h| h.puts f end
      end
    rescue Errno
      # Forget it if there isn't enough disk space.
    end

    def push l
      Readline::HISTORY.push l unless l.empty?
    end

    private

    def entry_str i
      i == 1 ? "entry" : "entries"
    end

  end

  class <<self

    attr_accessor :prompt, :show, :colour

    attr_reader :histfile
    def histfile= hf
      @histfile = hf
      if @history then
        @history.finish @histmax
        @history = History.new @histfile
      end
    end

    # Maximum number of history entries.
    attr_accessor :histmax

    # Whether to hide entries starting with whitespace.
    attr_accessor :histhid

    # Shell prefix and Pipe suffix
    attr_accessor :sh_pref, :pi_suff

    # Whether <code>Kernel#exit</code> should be caught.
    attr_accessor :catch_exit

    private

    def inherited sub
      sub.class_eval {
        s = superclass
        @prompt     = s.prompt
        @show       = s.show
        @colour     = s.colour
        @histfile   = s.histfile
        @histmax    = s.histmax
        @histhid    = s.histhid
        @sh_pref    = s.sh_pref
        @pi_suff    = s.pi_suff
        @catch_exit = s.catch_exit
      }
    end

    def history_file
      if @history then
        yield
      else
        @history = History.new @histfile
        begin
          yield
        ensure
          @history.finish @histmax
          @history = nil
        end
      end
    end

    public

    private :new
    def open obj
      history_file do
        i = new obj
        yield i
      end
    end

    def run obj
      open obj do |i| i.run end
    end

    def hist_add l
      return if @histhid and l == /\A[ \t]+/
      lst = Readline::HISTORY[-1] if Readline::HISTORY.length > 0
      @history.push l unless l == lst
    end

  end

  self.prompt     = "%(32)c%i%c:%1c%03n%c%> "
  self.show       = 1
  self.colour     = true
  self.histfile   = nil
  self.histmax    = 500
  self.histhid    = true
  self.sh_pref    = "."
  self.pi_suff    = " |"
  self.catch_exit = nil

  private

  def initialize obj
    @obj = obj
    @n = 0
  end

  OLDSET = <<-EOT
    _, __, ___ = nil, nil, nil
    proc { |r,n|
      Array === __ or __ = []
      Hash === ___ or ___ = {}
      unless r.nil? or r.equal? __ or r.equal? ___ then
        _ = r
        __.delete r rescue nil
        __.unshift r
        ___[ n] = r
      end
    }
  EOT

  autoload :Etc,    "etc"
  autoload :Socket, "socket"

  def cur_prompt
    t = Time.now
    self.class.prompt.gsub /%(?:
                               \(([^\)]+)?\)
                             |
                               ([+-]?[0-9]+(?:\.[0-9]+)?)
                             )?(.)/nx do
      case $3
        when "s" then @obj.to_s
        when "i" then $1 ? (@obj.send $1) : @obj.inspect
        when "n" then "%#$2d" % @n
        when "t" then t.strftime $1||"%X"
        when "u" then Etc.getpwuid.name
        when "h" then Socket.gethostname
        when "w" then cwd_short
        when "W" then File.basename cwd_short
        when "c" then (colour *($1 || $2 || "").split.map { |x| x.to_i }).to_s
        when ">" then Process.uid == 0 ? "#" : ">"
        when "%" then $3
        else          $&
      end
    end
  end

  def colour *c
    if self.class.colour then
      s = c.map { |i| "%d" % i }.join ";"
      "\e[#{s}m"
    end
  end

  def switchcolour *c
    s = colour *c
    print s if s
  end

  def cwd_short
    r = Dir.pwd
    h = Etc.getpwuid.dir
    r[ 0, h.length] == h and r[ 0, h.length] = "~"
    r
  end

  def readline
    r, @previous = @previous, nil
    r or @n += 1
    cp = cur_prompt
    loop do
      begin
        l = Readline.readline r ? "" : cp
      rescue Interrupt
        puts "^C  --  #{$!.inspect}"
        retry
      end
      if r then
        break if l.nil?
        r << $/ << l
        break if l.empty?
      else
        return if l.nil?
        next unless l =~ /\S/
        r = l
        break unless l =~ /\\+\z/ and $&.length % 2 != 0
      end
    end
    cp.strip!
    cp.gsub! /\e\[[0-9]*(;[0-9]*)*m/, ""
    @file = "#{self.class}/#{cp}"
    self.class.hist_add r
    r
  end

  # :stopdoc:
  ARROW    = "=> "
  ELLIPSIS = "..."
  # :startdoc:

  def display r
    return if r.nil?
    show = (self.class.show or return)
    i = r.inspect
    if show > 0 then
      siz, = $stdout.winsize
      siz *= show
      siz -= ARROW.length
      if i.length > siz then
        i.cut! siz-ELLIPSIS.length
        i << ELLIPSIS
      end
    end
    i.prepend ARROW
    puts i
  end

  def pager doit
    if doit then
      IO.popen ENV[ "PAGER"]||"more", "w" do |pg|
        begin
          stdout = $stdout.dup
          $stdout.reopen pg
          yield
        ensure
          $stdout.reopen stdout
        end
      end
    else
      yield
    end
  end

  public

  class Exit      < Exception ; end
  class CmdFailed < Exception ; end

  def run *precmds
    bind = @obj.empty_binding
    precmds.each { |l| eval l, bind }
    oldset = eval OLDSET, bind
    @cl = eval "caller.length", bind
    while l = readline do
      re_sh_pref = /\A#{Regexp.quote self.class.sh_pref}/
      re_pi_suff = /#{Regexp.quote self.class.pi_suff}\z/
      switchcolour
      begin
        pg = l.slice! re_pi_suff
        r = pager pg do
          unless l =~ re_sh_pref then
            eval l, bind, @file
          else
            call_system $', bind
          end
        end
        oldset.call r, @n
        display r
      rescue Exit
        wait_exit and break
      rescue CmdFailed
        oldset.call $?, @n
        switchcolour 33
        puts "Exit code: #{$?.exitstatus}"
      rescue LoadError
        oldset.call $!, @n
        show_exception
      rescue ScriptError
        if l[ $/] then
          switchcolour 33
          puts $!
        else
          @previous = l
        end
      rescue SystemExit
        break if wait_exit
        oldset.call $!, @n
        show_exception
      rescue Exception
        oldset.call $!, @n
        show_exception
      ensure
	switchcolour
      end
    end
    puts
  ensure
    done
  end

  protected

  def done
  end

  private

  def wait_exit
    c = self.class.catch_exit
    c and c.times { print "." ; $stdout.flush ; sleep 1 }
    true
  rescue Interrupt
    puts
  end

  def show_exception
    unless $!.to_s.empty? then
      switchcolour 31, 1
      print $!
      print " " unless $!.to_s =~ /\s\z/
    end
    switchcolour 31, 22
    puts "(#{$!.class})"
    switchcolour 33
    bt = $@.dup
    if bt.length > @cl then
      bt.pop @cl
      bt.push bt.pop[ /(.*:\d+):.*/, 1]
    end
    puts bt
  end

  def call_system l, bind
    l.strip!
    raise Exit if l.empty?
    eot = "EOT0001"
    eot.succ! while l[ eot]
    l = eval "<<#{eot}\n#{l}\n#{eot}", bind, @file
    system l or raise CmdFailed
    nil
  end

end

