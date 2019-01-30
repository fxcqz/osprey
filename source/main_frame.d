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
import gtk.Widget;
import gtk.Toolbar;
import gtk.ToolButton;
import gtk.Dialog;

import glib.Timeout;

import commands;
import matrix;
import room;
import ui : LoginDialog;


class ChatPane : ScrolledWindow {
  Grid grid;
  int currentLine;

  this() {
    // TODO make messages stick to the bottom
    super();
    this.grid = new Grid();
    this.grid.setColumnSpacing(10);
    this.add(this.grid);
  }

  void addMessage(Message message) {
    Label user = new Label(message[0]);
    user.setSelectable(true);
    user.setXalign(1);
    user.setMaxWidthChars(30);
    user.setLineWrap(true);
    Label text = new Label(message[1]);
    text.setSelectable(true);
    text.setXalign(0);
    text.setLineWrap(true);
    this.grid.attach(user, 0, this.currentLine, 1, 1);
    this.grid.attach(text, 1, this.currentLine, 1, 1);
    this.currentLine += 1;
  }
}


class MainFrame : MainWindow {
  // use getNthPage with this id to obtain the room widget
  int currentPage;
  // map room id's to room objects (would this be better with page id?)
  Room[int] rooms;
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

  void startUpdateTimeout() {
    if (this.updateTimeout is null) {
      this.updateTimeout = new Timeout(&this.updateChat, 1, true);
      this.roomPanels.addOnSwitchPage(&this.switchPage);
    }
  }

  void joinInitialRooms() {
    foreach (room; this.connection.rooms) {
      auto pane = new ChatPane();
      this.currentPage = this.roomPanels.appendPage(pane, room.roomID);
      this.rooms[this.currentPage] = room;
    }
    this.roomPanels.setCurrentPage(this.currentPage);
    this.currentRoom = this.connection.rooms[$ - 1];
    this.startUpdateTimeout();
    this.showAll();
  }

  void joinRoom(string room) {
    bool connected = this.connection.join(room);
    if (connected) {
      // setup ui for new room
      auto pane = new ChatPane();

      this.currentPage = this.roomPanels.appendPage(pane, room);
      this.showAll();
      this.roomPanels.setCurrentPage(this.currentPage);

      // most recently added room is the relevant one
      this.currentRoom = this.connection.rooms[$ - 1];
      this.rooms[this.currentPage] = this.currentRoom;

      this.startUpdateTimeout();
    }
  }

  bool updateChat() {
    // looks for new messages in the current room's buffer
    // TODO receive from another thread
    this.sync();
    ChatPane panel = cast(ChatPane) this.roomPanels.getNthPage(this.currentPage);

    foreach (msg; this.currentRoom.buffer) {
      panel.addMessage(msg);
    }

    panel.showAll();
    this.currentRoom.buffer = [];

    return true;
  }

  void sendMessage(string message) {
    this.connection.sendMessage(this.currentRoom.roomID, message);
    this.updateChat();
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
      this.sendMessage(messageText);
      break;
    case CommandKind.LOGIN:
      this.connection.login();
      break;
    case CommandKind.JOIN:
      // TODO we just handle joining one room for the time being
      this.joinRoom(command.args[0]);
      break;
    case CommandKind.INVALID:
      // invalid command... do nothing
      break;
    }

    // clear the entry box
    this.inputText.setText("");
  }

  /// onLogin
  /// `ToolButton` dispatch for logging in to matrix, fired from the `clicked`
  /// event.
  void onLogin(ToolButton tb) {
    import std.file : exists;
    if (exists("config.json")) {
      // read from the existing file
      Config conf = Config("config.json");
      this.connection.setConfig(conf);
      this.connection.login();
    } else {
      auto dlg = new LoginDialog(this);
      scope (exit) dlg.destroy();

      dlg.showAll();

      if (dlg.run() == ResponseType.ACCEPT) {
        Config conf = Config(
          dlg.usernameEntry.getText(),
          dlg.passwordEntry.getText(),
          dlg.addressEntry.getText(),
        );

        this.connection.setConfig(conf);
        this.connection.login();

        if (this.connection.connected && dlg.rememberMe.getActive()) {
          // only write config if we successfully connected
          conf.save("config.json");
        }
      }
    }

    // join initial rooms
    if (this.connection.rooms.length > 0) {
      this.joinInitialRooms();
    }
  }

  ///
  void onJoin(ToolButton tb) {
    import std.string : startsWith;

    string response = "";
    auto dlg = new Dialog(
      "Join a new room",
      this,
      DialogFlags.MODAL,
      ["Ok", "Cancel"],
      [ResponseType.ACCEPT, ResponseType.CANCEL]
    );
    scope (exit) dlg.destroy();

    auto roomEntry = new Entry();
    roomEntry.addOnActivate(delegate void(Entry widget) {
      dlg.response(ResponseType.ACCEPT);
    });

    auto vbox = dlg.getContentArea();
    vbox.add(new Label("Enter a room name"));
    vbox.add(roomEntry);
    dlg.showAll();

    if (dlg.run() == ResponseType.ACCEPT) {
      string roomName = roomEntry.getText();
      if (roomName.length > 0 && roomName.startsWith("#")) {
        response = roomName ~ ":" ~ this.connection.config.serverName();
        this.joinRoom(response);
      }
    }
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

  void switchPage(Widget panel, uint id, Notebook nb) {
    this.currentPage = id;
    this.currentRoom = this.rooms[id];
    this.updateChat();
  }

  void createToolbar(Box mainBox) {
    Toolbar tb = new Toolbar();

    auto btnLogin = new ToolButton(StockID.NETWORK);
    btnLogin.setLabel("Login");
    btnLogin.addOnClicked(&this.onLogin);
    tb.insert(btnLogin);

    auto btnAdd = new ToolButton(StockID.ADD);
    btnAdd.setLabel("Join Room");
    btnAdd.addOnClicked(&this.onJoin);
    tb.insert(btnAdd);

    mainBox.packStart(tb, false, false, 0);
  }

  this() {
    super("Osprey Client");
    setDefaultSize(1024, 768);

    // setup matrix stuff
    this.connection = new Matrix();

    // setup layout stuff
    auto mainBox = new Box(Orientation.VERTICAL, 0);

    // toolbar
    this.createToolbar(mainBox);

    // room panes
    this.roomPanels = new Notebook();

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
