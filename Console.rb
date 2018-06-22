require_relative "libs\\GUI.rb"

# Ruby bindings for p and puts
# ----------------------------
# Here we redefine `puts` and `p` to append to a global consoleLog array. This will be later returned
# from HTTP EVAL.
ConsoleBindings = <<-initScript
  $consoleLog = []
  def puts(o)
      $consoleLog.push(o.to_s)
      return {:type=>:VOID}
  end
  def p(o)
      $consoleLog.push(o.inspect.to_s)
      return {:type=>:VOID}
  end
initScript

# Ruby console wrapper
# ---------------------------
# The current implementation of HTTP EVAL returns :type and :data, where :type within [:VOID, :DATA, :ERROR]
# For the console we also want to include the `$consoleLog` which has been bound in the console bindings above.
# To do so we must wrap the user's requests, and ultimately execute more ruby script than normal, to return
# the log as well as the data and type.
#
# The wrapper below achieves this.
# code is injected into #codeFromJavaScript from javascript.
# the code is then parsed by ruby's eval()
# the log is cloned, and then cleared
# finally the return value is created and filled with the return data required. The final request
# ultimately will look like this:
# {:type=>[?:ERROR,:DATA],:data=>{:type=>[?:ERROR,:DATA,:VOID],:log=>$consoleLog, :data=>RESULTS}}
consoleWrapper=<<endWrapper
  require 'json'
  code = '{"data":#codeFromJavaScript}'
  $stdout << JSON.parse(code)["data"].unpack("m*")[0]
  data = $console_binding.eval(JSON.parse(code)["data"].unpack("m*")[0])
  log = $consoleLog.clone
  $consoleLog = []
  if data == {:type=>:VOID}
    data = nil
    type = "VOID"
  else
    type = "DATA"
  end
  {:data=>data,:type=>type,:log=>log}
endWrapper

# Uses a bit of an odd method of injecting the code, but this turns out to be the safest way of injecting
# code into injected code, while also maintaining error messages (from my testing at least):
# (JS) JSON.stringify(JSON.stringify(code)): 1+1 ==> (JS) "\"1+1\"" ==> (Ruby) JSON.parse() ==> "1+1" ==> (Ruby) eval()
consoleWrapper = consoleWrapper.to_json.sub("#codeFromJavaScript","\" + JSON.stringify(btoa(code)) + \"")

# HTML body:
DefaultBody=<<ENDBODY
    <html>
        <head>
            <title>Ruby Console</title>

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
                //AUTOCOMPLETION:
                //---------------------------------------------------------------------------
                //Ruby.eval(getPreText() + ".methods",function(methods)
                //   //Display methods in popup
                //})
                function getPreText(){
                  var cons = $(".console").console()
                  var cpos = cons.inputEditor.getCursorPosition();
                  var pretext = null
                  rowtext = cons.inputEditor.getValue().split("\\n")[cpos["row"]]
                  if(rowtext.substr(cpos["column"]-1,1)=="."){
                    var char = ".";
                    var pos = cpos["column"]-2;
                    while(!char.match(/\\s/) && pos != 0){
                      pos--
                      char = rowtext.substr(pos,1)
                    }
                    pretext = rowtext.substr(pos==0 ? 0 : pos+1,cpos["column"]-pos)
                  }
                  return pretext
                }
                //---------------------------------------------------------------------------

                $(function(){
                    var cons = $(".console").console({
                        onInput: function(code){
                            //Wrap text in lambda. Call lamda (inputted into repl)
                            //Return hash containing log and data
                            code = #{consoleWrapper}
                            console.log(code)

                            evaluateRuby(code,function(data){
                                var ret = JSON.parse(data)
                                console.log(ret)
                                switch(ret.type){
                                    case "DATA":
                                      if(ret.data.type=="DATA"){
                                        cons.output(ret.data.data)
                                      }
                                      ret.data.log.forEach(function(line){
                                          cons.log(line);
                                      });
                                      break;
                                    case "ERROR":
                                        cons.error(ret.data);
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
ENDBODY

# Custom icon:
CustomIcon = "iVBORw0KGgoAAAANSUhEUgAAABEAAAAQBAMAAAACH4lsAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAB5QTFRFAAAA8ywk+Le0/MrI3Scg//z8uiAZxyIb1dWu////j5XGNgAAAAF0Uk5TAEDm2GYAAAABYktHRAnx2aXsAAAACXBIWXMAAABIAAAASABGyWs+AAAAVklEQVQI12NgAAJBIQYIYBQUUoCwBAWFlaBCgs5GChAhEVdjJYiQi1uaC0TIxcVFECxUDmOJl5dAWeXl5RCWOJBVAmeVI1glEL1gwMDQCGU1MHRAQQMABYIXnXQcB+wAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTgtMDUtMjNUMTk6NTc6MDIrMDM6MDAMfzIiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE4LTA1LTIzVDE5OjU3OjAxKzAzOjAwTMqQAwAAAABJRU5ErkJggg=="

#Allow storage of local variables without affecting wrapper scope
$console_binding = GUI::Sandbox.new.get_binding
$console_binding.eval(ConsoleBindings)

# Create a new GUI
gui = GUI::GUI.new(DefaultBody,{
  :rubyInitScript => ConsoleBindings,
  :customIcon => CustomIcon
})

# Show the GUI syncronously
gui.show()
