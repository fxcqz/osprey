import matrix;
import secret : roomAddress;

void main(string[] args) {
  import std.stdio : writeln;

  writeln(args);

  Config config = Config("config.json");
  Matrix matrix = new Matrix(config);

  matrix.login();
  matrix.join(roomAddress);
  auto data = matrix.sync();

  writeln(data);
}
