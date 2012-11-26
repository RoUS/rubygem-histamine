# Histamine - Manage `bash` histories

**Histamine** is still very much in the primitive prototyping stage.
It provides tools to allow you to record command histories keyed by
username and hostname, with the eventual goal of being able to read
them back into your shell's active history.

Hopefully, using a Web app and a piped command interface, together
with the `-a`, `-n`, and `-r` options to the `history` command (see
{http://www.gnu.org/software/bash/manual/bashref.html#Bash-History-Builtins} ),
you'll be able to save command histories from various identities and
reload them, even into different identities.

## Installation

Add this line to your application's Gemfile:

    gem 'histamine'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install histamine

## Usage

    require('histamine')

    cmds_00 = Histamine::Timebucket.new(:time => Time.parse('yesterday'),
                                        :user => 'root')

    cmds_00 << 'gem list -r histamine'
    cmds_00 << [ 'gem install histamine', 'cd /tmp' ]
    cmds_01 = Histamine::Timebucket.new(:time => Time.now,
                                       :user => 'magoo')
    cmds_01.commands = [ 'emacs README.md', 'rake yard' ]
    hist = Histamine::History.new
    hist << [ cmds_00, cmds_01 ]


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

---

## To do

* Commands as first-class objects; command string + array of tags (for
  *per*-directory history, maybe?)


## Notes for investigation:

* Set HISTFILE to a named pipe?  Bidirectional pipes?
* `history -[aw] /dev/stdout | wherever'
* `wherever | history -[nr] /dev/stdin` (no workee?)
* `PROMPT_COMMAND='history -a >(tee -a ~/.bash_history | logger -t "$USER[$$] $SSH_CONNECTION")'`
  from {http://jablonskis.org/2011/howto-log-bash-history-to-syslog/}
* PUT webapp/upload?user=\*;host=\*;tags=\*,\*,\*
* GET webapp/download?user=\*;host=\*;tags=\*

