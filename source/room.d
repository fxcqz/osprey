module room;

class Room {
  string roomID;
  // TODO buffer should be something better than string[]
  string[] buffer;

  this (string id) {
    this.roomID = id;
  }
}
