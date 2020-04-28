//Get language_tools extension:
fetch("libs/js/ace/ext-language_tools.js")
  .then(function(response){return response.text()})
  .then(eval)
  .then(function(){
    var langTools = ace.require("ace/ext/language_tools");
    var cons = $(".console").console();
    cons.inputEditor.setOptions({
      enableBasicAutocompletion:true,
      enableLiveAutocompletion:true
    })
    cons.inputEditor.commands.on("afterExec",function(e){
      if(e.command.name=="insertstring"){
        if(e.args=="."||e.args==":"){
          cons.inputEditor.execCommand("startAutocomplete");
        }
      }
    })
    var util = ace.require("ace/autocomplete/util")
    cons.inputEditor.execCommand("startAutocomplete")
    //Build autocompleter
    langTools.setCompleters([{
      getCompletions: function(editor,session,pos,prefix,callback){
        //Get line containing object to perform intellisense on.
        var line = editor.session.getLine(pos.row).substr(0,pos.column);
        
        //Before wasting time, make sure intellisense is required.
        if(line.substr(-1)!="." && line.substr(-2)!="::") return callback(null,null);
        
        var chars = line.split("");
        var start_col = pos.column-1;
        var strMode = false;
        
        //Because ruby lacks strong typing, we can only identify methods of
        //results at runtime. Accessing methods may cause damage to runtime,
        //thus we try to restrict this as much as possible by only tracing
        //through chars which can be in var names or attribute accessors
        //like . and ::
        //We get the start_col also so we can use statements like var x = a.b.c whilst
        //still getting intellisense.
        while(!/[^A-Za-z0-9_\.:@$]/.test(chars[start_col]) && start_col != 0){
          debugger;
          start_col--;
        }
        line = start_col!=0 ? line.substr(start_col+1) : line;
        
        //Assume this is valid syntax. If it isn't an error will throw but we'll
        //simply stealthly ignore it.
        if(line.substr(-1)=="."){
          //If . then find methods
          var objectSpecified = line.substr(0,line.length-1);
          Ruby.eval(`$console_binding.eval("${objectSpecified}.methods")`,function(response){
            if(response.type=="ERROR") return callback(null,null);
            var method_list = response.data;
            callback(null,method_list.map(function(method){
              return {name:method,value:method,score:0};
            }))
          })
        } else if(line.substr(-2)=="::"){
          //If :: then find constants
          var objectSpecified = line.substr(0,line.length-2);
          Ruby.eval(`$console_binding.eval("${objectSpecified}.constants")`,function(response){
            if(response.type=="ERROR") return callback(null,null);
            var const_list = response.data;
            callback(null,const_list.map(function(method){
              return {name:method,value:method,score:0};
            }));
          });
        };
      }
  }]);
});