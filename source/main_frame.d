module main_frame;

import std.json;
import std.stdio : writeln;

import gtk.MainWindow;
import gtk.Label;
import gtk.Box;
import gtk.Notebook;
import gtk.ScrolledWindow;
import gtk.Grid;
import gtk.Entry;
import gtk.Button;

import glib.Timeout;

import commands;
import matrix;
import room;


class ChatPane : ScrolledWindow {
  Grid grid;
  int currentLine;

  this() {
    super();
    this.grid = new Grid();
    this.add(this.grid);
  }

  void addMessage(string message) {
    Label label = new Label(message);
    label.setSelectable(true);
    label.setXalign(0);
    label.setLineWrap(true);
    this.grid.attach(label, 0, this.currentLine, 1, 1);
    this.currentLine += 1;
  }
}


class MainFrame : MainWindow {
  // use getNthPage with this id to obtain the room widget
  int currentPage;
  // map room id's to room objects (would this be better with page id?)
  Room[string] rooms;
  Room currentRoom;
  // main matrix connection member
  Matrix connection;

  // UI stuff
  Notebook roomPanels;
  Entry inputText;
  Timeout updateTimeout;

  void sync() {
    // do a general sync of matrix and send messaged to their respective rooms
    // TODO run in another thread?
    JSONValue data = this.connection.sync();
    this.connection.extractMessages(data);
  }

  void joinRoom(string room) {
    bool connected = this.connection.join(room);
    if (connected) {
      // initial sync
      this.sync();

      // setup ui for new room
      auto pane = new ChatPane();

      this.currentPage = this.roomPanels.appendPage(pane, room);
      this.showAll();
      this.roomPanels.setCurrentPage(this.currentPage);

      // most recently added room is the relevant one
      this.currentRoom = this.connection.rooms[$ - 1];
      this.rooms[this.currentRoom.roomID] = this.currentRoom;

      if (this.updateTimeout is null) {
        this.updateTimeout = new Timeout(&this.updateChat, 1, true);
      }
    }
  }

  bool updateChat() {
    // looks for new messages in the current room's buffer
    // TODO receive from another thread
    ChatPane panel = cast(ChatPane) this.roomPanels.getNthPage(this.currentPage);

    foreach (msg; this.currentRoom.buffer) {
      panel.addMessage(msg);
    }

    panel.showAll();
    this.currentRoom.buffer = [];

    return true;
  }

  /// onSendMessage
  /// Do some parsing on the message to determine if it's an internal Osprey
  /// command.
  /// This function will call sendMessage if it determines there is something
  /// worth sending. Then it will clear the UI text entry.
  void onSendMessage() {
    string messageText = this.inputText.getText();
    Command command = parseCommand(messageText);

    final switch (command.kind) {
    case CommandKind.UNKNOWN:
      // unknown command - probably a normal message so continue as expected
      // TODO
      writeln(messageText);
      break;
    case CommandKind.LOGIN:
      this.connection.login();
      break;
    case CommandKind.JOIN:
      // TODO we just handle joining one room for the time being
      this.joinRoom(command.args[0]);
      break;
    }

    // clear the entry box
    this.inputText.setText("");
  }

  /// onSendMessage
  /// `Entry` dispatch for `onSendMessage`, fired from the `activate` event.
  /// This immediately calls `onSendMessage()` with no arguments.
  void onSendMessage(Entry widget) {
    this.onSendMessage();
  }

  /// onSendMessage
  /// `Button` dispatch for `onSendMessage`, first from the `clicked` event.
  /// This immediately calls `onSendMessage()` with no arguments.
  void onSendMessage(Button widget) {
    this.onSendMessage();
  }

  this() {
    super("Osprey Client");
    setDefaultSize(640, 480);

    // setup matrix stuff
    Config config = Config("config.json");
    this.connection = new Matrix(config);

    // setup layout stuff
    auto mainBox = new Box(Orientation.VERTICAL, 0);

    // room panes
    this.roomPanels = new Notebook();
    ChatPane welcomePane = new ChatPane();

    this.currentPage = this.roomPanels.appendPage(welcomePane, "Welcome");

    mainBox.packStart(this.roomPanels, true, true, 0);

    // text entry
    auto inputBox = new Box(Orientation.HORIZONTAL, 0);

    this.inputText = new Entry();
    this.inputText.addOnActivate(&this.onSendMessage);

    auto inputButton = new Button("Send");
    inputButton.addOnClicked(&this.onSendMessage);

    inputBox.packStart(this.inputText, true, true, 0);
    inputBox.packStart(inputButton, false, false, 0);

    mainBox.packStart(inputBox, false, false, 0);

    this.add(mainBox);
    this.showAll();
  }
}
