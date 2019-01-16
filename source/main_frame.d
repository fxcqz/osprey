module main_frame;

import gtk.MainWindow;
import gtk.Label;
import gtk.Box;
import gtk.Notebook;
import gtk.ScrolledWindow;
import gtk.Grid;
import gtk.Entry;
import gtk.Button;

import commands;
import matrix;
import room;


class MainFrame : MainWindow {
  // use getNthPage with this id to obtain the room widget
  int currentPage;
  // map room id's to room objects (would this be better with page id?)
  Room[string] rooms;
  // main matrix connection member
  Matrix connection;

  // UI stuff
  Notebook roomPanels;
  Entry inputText;

  void joinRoom(string room) {
    bool connected = this.connection.join(room);
    if (connected) {
      auto scroller = new ScrolledWindow();
      auto chatGrid = new Grid();
      scroller.add(chatGrid);
      this.currentPage = this.roomPanels.appendPage(scroller, room);
      this.showAll();
      this.roomPanels.setCurrentPage(this.currentPage);
    }
  }

  /// onSendMessage
  /// Do some parsing on the message to determine if it's an internal Osprey
  /// command.
  /// This function will call sendMessage if it determines there is something
  /// worth sending. Then it will clear the UI text entry.
  void onSendMessage() {
    import std.stdio : writeln;

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
    auto scroller = new ScrolledWindow();

    auto chatGrid = new Grid();
    scroller.add(chatGrid);

    this.currentPage = this.roomPanels.appendPage(scroller, "Welcome");

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
