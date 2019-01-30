module ui;

import gtk.Window;
import gtk.Dialog;
import gtk.Label;
import gtk.Entry;
import gtk.CheckButton;

class LoginDialog : Dialog {
  Entry usernameEntry, passwordEntry, addressEntry;
  CheckButton rememberMe;

  this(Window parent) {
    super(
      "Connect to a server",
      parent,
      DialogFlags.MODAL,
      ["Ok", "Cancel"],
      [ResponseType.ACCEPT, ResponseType.CANCEL]
    );

    auto vbox = this.getContentArea();

    auto userLbl = new Label("Username");
    userLbl.setXalign(0);
    this.usernameEntry = new Entry();
    vbox.add(userLbl);
    vbox.add(this.usernameEntry);

    auto passLbl = new Label("Password");
    passLbl.setXalign(0);
    this.passwordEntry = new Entry();
    this.passwordEntry.setVisibility(false);
    vbox.add(passLbl);
    vbox.add(this.passwordEntry);

    auto addrLbl = new Label("Address");
    addrLbl.setXalign(0);
    this.addressEntry = new Entry();
    vbox.add(addrLbl);
    vbox.add(this.addressEntry);

    this.rememberMe = new CheckButton("Remember credentials");
    vbox.add(this.rememberMe);

    this.resize(480, 250);
  }
}
