class ChatMemory {
  List<Map<String, String>> history = [];

  void addMessage(String role, String content) {
    history.add({"role": role, "content": content});
    if (history.length > 10) {
      history.removeAt(0); 
    }
  }

  List<Map<String, String>> getHistory() {
    return history;
  }
}
