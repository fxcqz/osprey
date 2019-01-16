module commands;

enum CommandKind {
  UNKNOWN,
  LOGIN,
  JOIN,
}

struct Command {
  CommandKind kind;
  int argc;
  string[] args;

  this(CommandKind kind) {
    // useful for commands with no arguments
    this.kind = kind;
    this.argc = 0;
  }

  this(CommandKind kind, int argc, string[] args...) {
    this.kind = kind;
    this.argc = argc;
    this.args = args;
  }
}

Command parseCommand(string text) {
  import std.array : split;
  import std.algorithm.searching : startsWith;
  import std.conv : to;
  import std.uni : isWhite;

  if (text.length < 2 || !text.startsWith("/")) {
    return Command(CommandKind.UNKNOWN);
  }

  string[] txtCommand = text[1 .. $].split!isWhite;

  if (txtCommand.length == 0) {
    return Command(CommandKind.UNKNOWN);
  }

  Command result;

  switch (txtCommand[0]) {
  case "login":
    result = Command(CommandKind.LOGIN);
    break;
  case "join":
    result = Command(CommandKind.JOIN, to!int(txtCommand.length - 1), txtCommand[1 .. $]);
    break;
  default:
    result = Command(CommandKind.UNKNOWN);
    break;
  }

  return result;
}

;
