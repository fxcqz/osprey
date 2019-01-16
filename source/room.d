module room;

struct Room {
  string roomID;
  string[] buffer;

  this (string id) {
    this.roomID = id;
  }
}
