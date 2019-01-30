module room;

import matrix : Message;

class Room {
  string roomID;
  string[string] members;
  // TODO buffer should be something better than string[]
  Message[] buffer;

  this (string id, string[string] members) {
    this.roomID = id;
    this.members = members;
  }
}
