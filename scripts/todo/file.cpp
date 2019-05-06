
############# issue 1 ################

 static bool Lookup(const std::string& name) {
    auto it = ng_node_maps_.find(name);
    if (it == ng_node_maps_.end()) {
      return true;
    }
    return false;
  }


################ issue 2 #############

tatic std::vector<std::vector<int>> NgraphOpIntervals(
    std::vector<std::unique_ptr<framework::OperatorBase>>* ops) {
     
     NgraphEngine::feed_vars.clear();
     NgraphEngine::fetch_vars.clear();
     std::vector<std::vector<int>> intervals;

  std::vector<int> interval = {start, end};
      intervals.emplace_back(interval);


}


################ 

