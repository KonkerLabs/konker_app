class Log{
  Map<String, Function(Object)> logs = Map();
  Map<String, Function(Object)> errs = Map();
  static Log _instance;
  factory Log() {
    if (_instance == null) {
      _instance = new Log._internal();
    }
    return _instance;
  }

  Log._internal() {}

  void addLogFunc(String key, Function(Object) func){
    logs[key]=func;
  }
  void addErrFunc(String key, Function(Object) func){
    errs[key]=func;
  }
  void print(Object obj){
    for(var key in logs.keys){
      logs[key](obj);
    }
  }
  void outputError(Object err){
    for(var key in errs.keys){
      errs[key](err);
    }
  }
}