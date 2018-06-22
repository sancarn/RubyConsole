module GUI
  require 'webrick'
  require 'json'
  require 'win32/registry'

  INFOWORKS_ICON = "AAABAAIAICAAAAEAIAAoEAAAJgAAABAQAAABACAAKAQAAE4QAAAoAAAAIAAAAEAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///8F29vbDt3d3Q/b29sO29vbDtvb2w7b29sO29vbDtvb2w7b29sO29vbDtvb2w7b29sO29vbDtvb2w7b29sO29vbDtvb2w7b29sO3d3dD9vb2w7j4+MJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC3t7pKhYWDzWlpa/9oaGn/Z2do/2dnaP9nZ2j/Z2do/2dnaP9nZ2j/Z2do/2dnaP9nZ2j/Z2do/2dnaP9nZ2j/Z2do/2dnaP9nZ2j/Z2do/2dnaP9nZ2j/amhr/2hnaf92dnjQs7OzVAAAAAAAAAAAAAAAAAAAAAAAAAAAnZ2dh4qKjP+3t7n/qqqp/7GxsP+ysrL/srKy/7Kysv+8urT/uLi0/7Ozs/+ysrL/srKy/7Kysv+ysrL/srKy/7Kysv+ysrL/srKy/7Kysv+zs7P/vbe7/829x/+trK7/wbu//+zg6P99fH//jY2NkgAAAAAAAAAAAAAAALOzt0qpqan/oKCh/35+fv/X19f/7u7u//Hx8f/x8fH////2/77E5P/b3OT////v////9f////P/8fHx//Hx8f/x8fH/+vX1///6+P//+ff///n9///6//+11cD/UrJx/zCmWP8YjD7/CUwe/+7g6v+Af4H/s7OzVAAAAAAAAAAAp6enzqurq/9/f3/////////////////////////////j5vP/AATF/0pp9f8bPuz/HDnn/3yP7f/////////////////o7Oz/aMDO/33K3P+r1bf/UMZu/0C0Zv8xqFn/J6ZS/y6yWP8Ur0b/AE4S/+3i6/98fHzRAAAAAMzMzAWwsLL/dXV2/93d3f///////////////////////////wAZw/8IKeb/HUTt/z9s7/9NgvL/VoLs////////////usvP/wCMrf8AtNT/CbjW/wCZw/8ZhUb/KKNM/yelUv8fqU3/DKk//2DJf/+nwrD/wbzB/3Nzcv/f398I29vbDrKysv93d3j/9PT0//////////////////////9Va9T/ABzd/xc37/8vWO7/O2rv/zVq7f////r///////////8AiqP/AK7O/wCz0v8AttX/AMLn/wOQn/8Yojb/G6JH/4jMn//+9fr///////r6//+xs7T/d3d5/93d3Q/Pz88QtbW3/3t7fP/19fX/////////////////0NTu/wAN0v8QMO7/HDvs/zFb7v8jWe3/1t/z/////////////////wCbwP8AweH/AM7w/wDU+P8A0ff/ALDR/8/dvv//////////////////////xqeW/6yflv9+gIP/z8/PEM/PzxC3t7f/fn5+//b29v////////////////8AGtD/HULq/w4t6P8bPez/IU/u/4Kf7f////////////////++07P/AKWp/wDW//8M3v//G+D//wDd//9R2/P/////////////////7OLd/9lvL//SMwD/saii/4GEiP/Pz88Qz8/PELq6uv+AgID/9vb2////////////PVTa/ylT6P8JKOX/ETDp/xAy7P8wV+j///////////////////n+/weOMv80uk//Dc7b/xff//8m3fz/Xt7z///////6////5rKS/95mHf/lSAD/wkAA/7CQfP+5w8n/hYWG/8/PzxDPz88Qurq8/4ODhP/19fX//////7a+7P8bReT/Cyvg/w8v5f8QMOj/ABLo////+f////////////////8ml0z/KbNW/zjKZP8+y1n/ntWZ////////////1ryr/9ZQAP/iUQD/zUYA/6WIeP/i9///+f///7e3t/+IiIn/z8/PEM/PzxC9vb7/hYWF//n59v//////CC/k/yxM4P8KKt3/Di7k/wAQ5f+yvO//////////////////arWC/x+wTv8wvV//N8tp/1/PhP///////////7FxS//hTwD/4VcB/79pNP/g8//////////////w8PD/t7e3/4yMjf/Pz88Qz8/PEL6+v/+Ghoj////5/zFK6P9Xduj/AB/W/w4u2/8AHuH/TWPl/////////////////7zYx/8WrUb/LrFZ/zTJZP85x2j///3///////98gIT/3k8A/+FdDf/bg07//v///////////////////+/v7/+2trj/j4+Q/8/PzxDPz88Qv7/A/5iXjP+QmuX/Q2Tx/wAezv8MLtn/Byba/wEi2v/////////////////++Pz/GaZH/y2vV/8wulz/IsZX/+Tv5////////////1ZBNf/wZA7/3VcG////////////////////////////7+/v/7i4t/+RkZL/z8/PEM/PzxDAwMH/oJyO/1Vw5f8AG87/ABTM/wAg1f8ABtP/8/T2/////////////////zasXf8wsVr/La9Y/xzAUv+q4bv/////////////////RTQp//VnEf/cVAL/99/O///////////////////////v7+//t7e4/5SUlf/Pz88Qz8/PEMLCwf+MjIz//Prv/87T8f+Xpeb/T2XZ/52q5/////////////////9xwYv/NLNe/yqrVf8gslD/Y86E//////////r///////////9BTVb/2lUG/+RlF//cVAH/+NzO/////////////////+/v7/+4uLj/lZWW/8/PzxDPz88QwsLB/4qKi//39vX/////////////////////////////////ud3E/zm1Yv8lok7/Ka9U/ym2WP//////NEzT/w047P9viuz//////7a+w/8/GwP/+2wV/+BjFv/ZTAD/8LqY////////////7+/v/7i4uP+VlZb/z8/PEM/PzxDAwMH/ioqL//T09P/////////////////////////////8+v87uGP/JZ9N/y2rVv8OqED//////4+a6v8AFOn/G1Hs/+fv+P///////////2t8iP91KgD/9WwY/+BkGP/bTQD/7ad9///////w8PD/t7e4/5SUlf/Pz88Qz8/PEMDAwP+JiYr/9PT0///////////////////////h5u//Nal2/zifSv8sqE7/DaQ9/9Pxz//i3f//ABrg/wAU6v/L1/T//////////////////////z5SXf+qQgT/62ka/+BkGf/bTQD/8KuA//P///+4uLf/k5OU/8/PzxDPz88Qv7+//4iIif/19fT/////////////////CIKW/wCqzf8OvuX/AJnE/xKNS/+Cz5H//////w803f8AB97/jZvu////////////////////////////9/r9/yEmKP/tYw//4mYa/+BkGf/eUQD/5LSW/7nEzP+QkJH/z8/PEM/PzxC9vb7/hYWG//b29v///////////3Otuv8Ar9D/AKrI/wCtyv8IxOf/AIWi//////9UbuD/AADJ/1ht4///////////////////////////////////////jp2n/4U0Av/saRn/4GUa/+JlGP/NSAD/t7e3/4yOk//Pz88Qz8/PELy8vP+Jhon///3//83i1P90tHj/AJWa/wC22v8Axeb/AM3w/wDK7f8AuuL///Dy///////a3vL////////////////////////////////////////////r8vb/SysX//JpFv/gZRr/42Ya/89PAf+zrKf/io6R/8/PzxDPz88Qvru+/3l8e/8Qmz3/FaZF/yiwR/8PsZ//AMr5/wDa/v8O3v//CuH//wDO/f+5yaX///////////////////////////////////////////////////////////9IOC7/8mcT/+BlGv/jZhr/z1AC/7Wtqf+Gio3/z8/PEM/PzxC9ub3/cnl1/x6kSf8wvF7/Nslj/z7IWf8AyOP/AN///zTj//8y5P//KLt7/wqVLv+py7X//////////////////////////////////////////////////////1Y/L//wZxP/4GUa/+NmGv/PUAP/tKyo/4OGif/Pz88Qz8/PELq2uv9tdnH/GbdN/yrKX/8zyWT/aNCI/77ksP/k8Pv/hdW6/zTEVv87y1//MLhe/wqgO/+bx6n////////////////////////////////////////////s+f//eToT/+xnFv/gZRr/42Ya/9BRA/+zq6j/fYCD/8/PzxDb29sOuba3/2hzbP9lyIX/yO3U///8////////////////////////jtmk/zHKYv81yGT/L7NZ/xKrRv+Mwp7//////////////////////////////////////5WepP/aUQD/4mYa/+BlGv/jZhr/zk8C/7Gppv96foH/3d3dD8zMzAW6urr/c3B0//Hk7f//////////////////////////////////////ndqx/yjJXf8wwGD/La9X/x+yT/99wJP////////////////////////////T5fD/uEcB/+dmF//gZRr/4GUa/+dnGf+5QQD/sLe8/3h5e//f398IAAAAAKqqqs6oqKf/gYGB////////////////////////////////////////////sOPB/x/JV/8wuVz/Kq1V/yu3Wf92wZD/////////////////3/D6/7lJBf/qZBP/42Ya/+NmGv/nZxn/52IR/28wC//Ay9L/h4eJ0QAAAAAAAAAAs7OwStLS1P9xcXL/gICA/97e3v/29vb/+fn5//j4+P/4+Pj/+Pj4//j4+P//////vd7H/xy7T/8gqE3/Gp5F/yarUf9gtXz//////+bx+P+SPgv/4lYA/9dZC//YWQv/1lcJ/75IAP9uMQz/oq20/5WVmP+zs7NUAAAAAAAAAAAAAAAAm5ubh9PT0/+jo6P/ZmZm/29vb/9wcHD/cHBw/3BwcP9wcHD/cHBw/3BwcP+AdXz/b29v/2JrZ/9ka2f/Xmdi/1tqYP9mbGn/ZGNl/3FhWf9vZmP/bmZj/25mY/9tZmP/b3d9/6izuv+ur7H/lpaWkgAAAAAAAAAAAAAAAAAAAAAAAAAAsLCwSqqqqs23t7f/ra2t/6urq/+rq6v/q6ur/6urq/+rq6v/q6ur/6urq/+vrK7/sa2v/7Gtr/+xrbD/sK2v/62srP+tra3/rK+x/6yvsf+sr7H/rK+x/6uusv+wsrL/p6en0K2trVQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMzMzAXb29sOzMzMD8jIyA7IyMgOyMjIDsjIyA7IyMgOyMjIDsjIyA7IyMgOyMjIDsjIyA7IyMgOyMjIDsjIyA7IyMgOyMjIDsjIyA7MzMwPyMjIDuPj4wkAAAAAAAAAAAAAAAAAAAAAAAAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALGxsW+hoaGHoKCghqSkooagoKCGoKCghqCgoIagoKCGoKCghqSiooato6uIt7C3cf///wUAAAAAAAAAAJCQkPyhoaH/z8/P/97c0f/Kycj/7ebQ/9jWz//Rz8//6tjV/+7Z2f/d09j/eKyJ/2mSdv+VjZP+////BcrKym+SkpL////////////V2vT/ABvl/xdH8f/F0f7//////zW3zv9HvNH/KKRE/wmeOf8Hrz3/k6qd/7KwsnHCwsKJsrKy////////////ABTX/xc/7/9Le+7//////4vP5f8Asdj/AMX0/x+ki//D7M3//////8q6uP+nqauIwsLChrS0s///////U27g/wAi6P8DL+r////9//////8ppWH/ANv//w/k///8/////9fE/9daDf+ze1r/q7W5hsbGxobGxLr/z9f+/wAm3/8ACuP/t8D1//////9quoT/EbhE/5vhnf//+///3VIA/8xgH//p8/r/1+Dl/6urrYbKysiGuLa5/xc86P8ADtP/UGfn///////C4Mz/BKU4/03ReP//////mkAK/+yOVP///////////9DQ0P+vr6+GzszIhpyit/9BXN7/FjXV////////////FKNC/xu4Sv///////////4M0Av/weC7////////////Q0ND/r6+zhsjIyIa/vrr/////////////////RbRj/wOgMv/v/uX/AA3p/+33//+RmJv/z0IA/+FeDf//////0tfa/6+vs4bGxsiGubi4///////l6+3/LrXD/waNTP+x6av/DiXx/5Gg9P///////////2NcWP/uWQD/5F4L/9HY3P+vs7WGxsbGhs2/yf/7+Oj/AJy5/wC43/8Ast///+7//2x/5P/////////////////m+f//nTsA/+xfCf+9dEj/r7rAhtXK04YygUz/B68v/wC9rf8A5f//ANPq/6vNnf///////////////////////////49CFP/uYgz/v3lQ/6u3vobQxc+JQ5Je/4fmpf/k9Nf///j7/zzHVP8EqTj/ls6p/////////////////+T8///DRwD/6mIP/754Tf+psrqIysrMb52Tmv//////////////////////P9Nw/waqPP+L06P////////////KZyn/8GEK/+5bAf+bdVz/srm+cQAAAACkpKb8iYmL/62trv+tra3/tK+y/7uvuP8yhU7/I3c//4Shkf+Kb2T/oEwZ/5xUK/+EXUf/lJ6n/v///wUAAAAAAAAAAMfHx225ub2Hurq8hrq6vIa+vL6GzsDKhs7CyobAvsCGvsLGhr7K0Ya9yc6IydDUcf///wUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

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
      if Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')[""]
        return :chrome
      elsif Dir.entries("#{ENV["SystemRoot"]}\\SystemApps\\").select {|s| s[/Microsoft\.MicrosoftEdge.+/]}.length
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
      end
      if request.path == "/favicon.ico"
        require 'Base64'
        if @parent.options[:customIcon]!=""
          response.body = Base64.decode64(@parent.options[:customIcon])
        else
          response.body = Base64.decode64(INFOWORKS_ICON)
        end
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
