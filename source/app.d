import core.thread : Thread;
import core.time : dur;
import std.concurrency;
import std.json : JSONValue;

import gtk.MainWindow;
import gtk.Label;
import gtk.Main;

import matrix;
import secret : roomAddress;

alias SyncData = shared(JSONValue);
alias SyncMessages = shared(string[][string]);

__gshared string currentRoom = "";

void worker(Tid parentId) {
  Config config = Config("config.json");
  Matrix matrix = new Matrix(config);

  matrix.login();
  matrix.join(roomAddress);
  currentRoom = matrix.currentRoom;
  SyncData data = matrix.sync();

  SyncMessages messages = cast(shared) matrix.extractMessages(data);

  send(parentId, messages);

  while (true) {
    data = matrix.sync();
    messages = cast(shared) matrix.extractMessages(data);

    if (messages) {
      send(parentId, messages);
    }

    Thread.sleep(dur!"usecs"(16));
  }
}

void main(string[] args) {
  import std.stdio : writeln;

  // TODO store rooms in a subclass of MainWindow
  // then cleanthis shit up
  // http://www.dsource.org/projects/gtkd/wiki/CodeExamples

  auto mainWorker = spawn(&worker, thisTid);

//  Main.init(args);
//
//  MainWindow win = new MainWindow("Hello World");
//  win.setDefaultSize(640, 480);
//  win.add(new Label("Hello world"));
//  win.showAll();
//
//  Main.run();

  // initial sync
  auto data = receiveOnly!SyncMessages();

  while (true) {
    SyncMessages messages = receiveOnly!SyncMessages();
    writeln(messages[currentRoom]);
  }
}
