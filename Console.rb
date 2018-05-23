require_relative 'webrick\webrick.rb'
require 'json'



DefaultBody=<<DEFAULT_BODY
    <html>
        <head>
            <title>Ruby Console</title>
            
            <link rel="shortcut icon" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAAQBAMAAAACH4lsAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAB5QTFRFAAAA8ywk+Le0/MrI3Scg//z8uiAZxyIb1dWu////j5XGNgAAAAF0Uk5TAEDm2GYAAAABYktHRAnx2aXsAAAACXBIWXMAAABIAAAASABGyWs+AAAAVklEQVQI12NgAAJBIQYIYBQUUoCwBAWFlaBCgs5GChAhEVdjJYiQi1uaC0TIxcVFECxUDmOJl5dAWeXl5RCWOJBVAmeVI1glEL1gwMDQCGU1MHRAQQMABYIXnXQcB+wAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTgtMDUtMjNUMTk6NTc6MDIrMDM6MDAMfzIiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE4LTA1LTIzVDE5OjU3OjAxKzAzOjAwTMqQAwAAAABJRU5ErkJggg==">

            
            <!--<  Include jQuery and Ace  >-->
            <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.2.9/ace.js"></script>

            <!--<  Include console.js and console.css >-->
            <script src="https://cdn.rawgit.com/TarVK/chromeConsole/version-1.0/console.js"></script>
            <link rel="stylesheet" href="https://cdn.rawgit.com/TarVK/chromeConsole/version-1.0/console.css" type="text/css" />

            <style>
                html, body, .console{
                    width: 100%;
                    height: 100%;
                    margin: 0px;
                }
            </style>

            <script>
                $(function(){
                    var cons = $(".console").console({
                        onInput: function(text){
                            evaluateRuby(text,function(data){
                                var ret = JSON.parse(data)

                                console.log(data)
                                console.log(ret)
                                switch(ret.type){
                                    case "DATA":
                                        cons.output(ret.data);
                                    case "VOID":
                                        ret.log.forEach(function(line){
                                            cons.log(line);
                                        });
                                        break;
                                    case "ERROR":
                                        cons.error(ret.msg);
                                        break;
                                }

                            });
                        },
                        mode: "ruby"
                    });
                    
                    $(".inputLine").click()
                    
                    //Exit before unload
                    $(window).on('beforeunload',function(){
                        request = new XMLHttpRequest
                        request.open("EXIT","")
                        request.send()
                        window.setTimeout(window.close,500)
                        return null
                    });
                    
                });
                function evaluateRuby(script,callback){
                    request = new XMLHttpRequest
                    request.onload = function(){
                        callback(this.responseText)
                    }
                    request.open("EVAL","")
                    request.send(script)
                }
            </script>
        </head>
        <body>
            <div class="console"></div>
        </body>
    </html>
DEFAULT_BODY

ConsoleBindings=<<CONSOLE_BINDINGS
    $consoleLog = []
    def puts(o)
        $consoleLog.push(o.to_s)
        return {:type=>:VOID}
    end
    def p(o)
        $consoleLog.push(o.inspect.to_s)
        return {:type=>:VOID}
    end
CONSOLE_BINDINGS

class Sandbox
    def get_binding
        binding
    end
end

#Make ruby evaluation binding:
$consoleBinding = Sandbox.new.get_binding
$consoleBinding.eval(ConsoleBindings)

#Making ruby console compatible on all OSes
if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    require 'win32/registry'
    chromePath = Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe')[""]
    `"#{chromePath}" --app="http://localhost:12357"`
elsif (/darwin/ =~ RUBY_PLATFORM) != nil
    `open -n -a "Google Chrome" --args --app="http://localhost:12357"`
end

#remove old reference of server
$server = nil
$server = WEBrick::HTTPServer.new(
  :Port=>12357,
  :DocumentRoot => Dir.pwd
)
trap 'INT' do $server.shutdown end


class RequestHandler < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(request,response)
        puts request.path
        resource = request.path.to_s[1..-1]
        
        if resource == ""
            response.body = DefaultBody
        else
            begin
                response.body = File.read(resource)
            rescue
                response.status = 404
            end
        end
    end
    
    def do_EVAL(request,response)
        begin
            result = $consoleBinding.eval(request.body)
            if result == {:type=>:VOID}
                response.body = {:type=>"VOID",:data=>"",:log=>$consoleLog}.to_json
            else
                response.body = {:type=>"DATA",:data=>result,:log=>$consoleLog}.to_json
            end

            $consoleLog=[] #reset log
        rescue Exception => e
            response.body = {:type=>"ERROR",:msg=>e.to_s}.to_json
        end
    end
    
    def do_EXIT(request,response)
        $server.shutdown
        response.body = ""
        
        #if chrome in debugmode then the following would be better:
        #chrome.close
    end
end
$server.mount '/', RequestHandler
$server.start
