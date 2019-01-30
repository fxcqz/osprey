module room;

import matrix : Message;

class Room {
  string roomID;
  string[string] members;
  // TODO buffer should be something better than string[]
  Message[] buffer;

  this (string id) {
    this.roomID = id;
  }

  void setMembers(string[string] members) {
    this.members = members;
  }
}
