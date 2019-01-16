import gtk.Main;

import main_frame;
import matrix;
import secret : roomAddress;

void main(string[] args) {
  import std.stdio : writeln;

  // TODO store rooms in a subclass of MainWindow
  // then clean this shit up
  // http://www.dsource.org/projects/gtkd/wiki/CodeExamples

  Main.init(args);
  new MainFrame();
  Main.run();

}
