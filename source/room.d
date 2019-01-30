module room;

class Room {
  // TODO store user ids and nicks in here
  string roomID;
  // TODO buffer should be something better than string[]
  string[] buffer;

  this (string id) {
    this.roomID = id;
  }
}
