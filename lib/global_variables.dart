class GlobalVariables {
  static final GlobalVariables _instance = GlobalVariables._internal();

  factory GlobalVariables(){
    return _instance;
  }

  GlobalVariables._internal();

  List<String> products = [];
}

final globalVariables = GlobalVariables();