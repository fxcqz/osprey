module room;

struct Room {
  string roomID;
  // Buffer of events if the room is not shown
  string[] buffer;

  this (string id) {
    this.roomID = id;
  }
}
