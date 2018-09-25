module GUI
  require 'webrick'
  require 'json'

  STANDARD_ADDITIONS = <<-EOF
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <script>
      function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

      window.addEventListener("load", function () {
        var Ruby = function () {
          function Ruby() {
            _classCallCheck(this, Ruby);
          }

          Ruby.prototype.eval = function _eval(code, callback) {
            var request = new XMLHttpRequest();
            request.onload = function () {
              callback(JSON.parse(this.responseText));
            };
            request.open("EVAL", "");
            request.send(code);
          };
          Ruby.prototype.exit = function _eval(code, callback) {
            var request = new XMLHttpRequest();
            //request.onload = window.close
            request.open("EXIT", "");
            request.send();
            return null;
          };
          return Ruby;
        }();

        window.Ruby = new Ruby();
      });
      window.addEventListener('beforeunload',function(){
        return window.Ruby.exit()
      });
    </script>
  EOF
  #THIS IS REQUIRED IN ICM 6.5.6 DUE TO AN ERROR IN WEBRICK. IF LOGGER OTHERWISE REQUIRED, YOU CAN MAKE YOUR OWN.
  #:Logger => WEBrick::Log.new(NullStream.new)
  class NullStream
     def <<(o); self; end
  end

  #A sandboxed binding
  class Sandbox
      def get_binding
          binding
      end
  end

  #Get default options each time they are requested (ensures logger and ruby binding are new)
  def self.getDefaultGuiOptions()
    {
      :customIcon           => "",
      :useStandardAdditions => true,
      :port                 => rand(10000..65535),
      :documentRoot         => Dir.pwd,
      :runtime              => nil,
      :runtimePath          => "",
      :autoPlayPolicy       => true,
      :logger               => WEBrick::Log.new(NullStream.new),
      :rubyBinding          => Sandbox.new.get_binding,
      :rubyInitScript       => "",
      :exitIfListenFailure  => true
    }
  end

  def self.bestRuntime(os)
    if os==:Win32
      require 'win32/registry'
      if Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths').keys.include? "chrome.exe"
        return :chrome
      elsif Dir.exists?("#{ENV["SystemRoot"]}\\SystemApps\\") && Dir.entries("#{ENV["SystemRoot"]}\\SystemApps\\").select {|s| s[/Microsoft\.MicrosoftEdge.+/]}.length
        return :edge
      else
        return :ie
      end
    elsif os==:Mac
      apps = Dir.entries("/Applications/")
      if apps.include? "Google Chrome.app"
        return :chrome
      elsif apps.include? "Safari.app"
        return :safari
      end
    elsif os==:Linux
      #Not sure how to test for an application being installed
      #so currently we'll simply brute force instead.
      return :linux
    end
    return :unknown
  end

  def self.launchRuntime(os,url,options)
    retHash = {:os=>os,:url=>url,:type=>options[:runtime],:object=>nil}
    case os
        when :Win32
          case options[:runtime]
            when :chrome
              chromePath = options[:runtimePath]=="" ? Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')[""] : options[:runtimePath]
              cmdArgs = "--app=\"#{url}\""
              if options[:autoPlayPolicy]
                 cmdArgs += " --autoplay-policy=no-user-gesture-required"
              end
              system("\"#{chromePath}\" #{cmdArgs}")
              #TODO OBJECT => WRAPPED DEBUG_PROTOCOL
              #retHash[:object] = chrome
              return retHash
            when :edge
              system("start microsoft-edge:#{url}")
              #TODO OBJECT => WRAPPED DEBUG_PROTOCOL
              #retHash[:object] = chrome
              return retHash
            when :ie
              require 'win32ole'
              ie = WIN32OLE.new("InternetExplorer.Application")
              ie.Navigate(url)
              ie.AddressBar = false
              retHash[:object] = ie
              return retHash
          end
        when :Mac
          case options[:runtime]
            when :chrome
              cmdArgs = "--app=\"#{url}\""
              if options[:autoPlayPolicy]
                 cmdArgs += " --autoplay-policy=no-user-gesture-required"
              end
              system("open -n -a \"Google Chrome\" --args #{cmdArgs}")
              #TODO OBJECT => WRAPPED DEBUG_PROTOCOL
              #retHash[:object] = chrome
              return retHash
            when :safari
              system("open -a Safari #{url}")
              #TODO OBJECT => WRAPPED OSAScript instance --> XX_Safari.rb
              #retHash[:object] = safari
              return retHash
          end
        when :Linux
          #chromium/chrome args:
          cmdArgs = "--app=\"#{url}\""
          if options[:autoPlayPolicy]
             cmdArgs += " --autoplay-policy=no-user-gesture-required"
          end

          #Not sure how to test for specific runtimes in linux, so for now they shall be ignored
          case true
            when system("chromium-browser #{cmdArgs}")
              #TODO OBJECT => WRAPPED DEBUG_PROTOCOL
              #retHash[:object] = chrome
              return retHash
            when system("google-chrome #{cmdArgs}")
              #TODO OBJECT => WRAPPED DEBUG_PROTOCOL
              #retHash[:object] = chrome
              return retHash
          end
    end
    return nil
  end

  def self.platform
    if (/cygwin|mswin|mingw|bccwin|wince|emx/i =~ RUBY_PLATFORM) != nil
      return :Win32
    elsif (/darwin/i =~ RUBY_PLATFORM) != nil
      return :Mac
    elsif (/linux/i =~ RUBY_PLATFORM) != nil
      return :Linux
    else
      return :Unknown
    end
  end

  module EvalHandler
      def do_EVAL(request,response)
          begin
              result = @parent.options[:rubyBinding].eval(request.body)
              response.body = {:type=>"DATA", :data=>result}.to_json
          rescue Exception => e
              response.body = {:type=>"ERROR",:data=>e.inspect}.to_json
          end
      end
  end

  module ExitHandler
      def do_EXIT(request,response)
          @parent.server.shutdown
          response.body = ""
      end
  end
  class RequestHandler < WEBrick::HTTPServlet::AbstractServlet
    include EvalHandler
    include ExitHandler

    def initialize(server,parent)
      super(server)
      @parent = parent
    end

    def do_GET(request,response)
      @parent.received_requests = true
      if request.path == "/"
        response.body = @parent.defaultHTML
      elsif request.path == "/favicon.ico"
        require 'Base64'
        if @parent.options[:customIcon]!=""
          response.body = Base64.decode64(@parent.options[:customIcon])
          return
        else
          response.body = Base64.decode64(INFOWORKS_ICON)
          return
        end
      else
        response.body = File.read(Dir.pwd + request.path)
      end
    end
  end

  class GUI
    attr_reader :defaultHTML, :options
    attr_accessor :server, :runtime, :received_requests

    def setArg(symbol,value)
      if !@running
        eval("@#{symbol}=JSON.parse('#{value.to_json}')")
      end
    end
    def initialize(defaultHTML,options={})
      @defaultHTML = defaultHTML

      #Merge options given with default options
      @options = ::GUI::getDefaultGuiOptions().merge(options)

      #Run initialize script - This can be used to instantiate standard methods
      @options[:rubyBinding].eval(@options[:rubyInitScript])

      #Making ruby console compatible on all OSes
      url = "http://localhost:#{@options[:port]}"

      if (os = ::GUI.platform)==:Unknown
        puts "Trapped Error: #{__LINE__}:: Platform unknown"
        exit
      end



      #Get best runtime if not otherwise provided:
      if @options[:runtime]==nil
        if (@options[:runtime]=::GUI.bestRuntime(os))==:unknown
          puts "Trapped Error: #{__LINE__}:: Runtime unknown"
          exit
        end
      end



      #Launch GUI based on runtime:
      if !(@runtime = ::GUI.launchRuntime(os,url,@options))
        puts "Trapped Error: #{__LINE__}:: Undefined runtime execution for runtime specified"
        exit
      end



      #Create server instance
      @server = WEBrick::HTTPServer.new(
        :Port         =>@options[:port],
        :DocumentRoot => @options[:documentRoot],
        :Logger       => @options[:logger],  #fixes some bugs...
        :AccessLog    => []
      )

      #Trap interupts and safely shutdown server
      trap 'INT' do
        @server.shutdown
      end

      #Inject standard html additions:
      if @options[:useStandardAdditions]
        if @defaultHTML[/<head>/]
          @defaultHTML = @defaultHTML.sub("<head>","<head>#{STANDARD_ADDITIONS}\r\n\r\n")
        elsif @defaultHTML[/<html>/]
          @defaultHTML = @defaultHTML.sub("<html>","<html><head>#{STANDARD_ADDITIONS}</head>")
        else
          @defaultHTML = "<head>" + STANDARD_ADDITIONS + "</head>\r\n\r\n" + @defaultHTML
        end
      end

      @server.mount '/', RequestHandler, self
    end

    #Start server method:
    def show()
      if @options[:exitIfListenFailure]
        Thread.new do
          Kernel.sleep(10)
          if !@received_requests
            puts "Error occurred while listening on port #{@options[:port]}"
          end
        end
      end
      @running=true
      @server.start
    end

    #Start server in new thread. Return the thread for easy syncing
    def showAsync()
      return Thread.new do
        @running=true
        @server.start
      end
    end

  end
end
