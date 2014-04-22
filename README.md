AnnotationHubServer3.0
======================

the ruby version of AnnotationHubServer

## How to install

### System dependencies

Make sure you have mysql and sqlite3 (with headers) installed. 

    sudo apt-get install libsqlite3-dev mysql-server libmysqlclient15-dev


## Installing Ruby and needed libraries

The simplest way is to use 
[rbenv](https://github.com/sstephenson/rbenv):

The following instructions are adapted from the 
[rbenv page](https://github.com/sstephenson/rbenv). It's worth reading this
to understand how rbenv works.

*Important note*: Never use `sudo` when working with a ruby that has been
installed by rbenv. rbenv installs everything in your home directory so
you should never need to become root or fiddle with permissions.

0. Make sure you do not have rvm installed. `which rvm` should not return 
   anything. If you do have it installed, refer to 
   [this page](http://stackoverflow.com/questions/3950260/howto-uninstall-rvm)
   for instructions on removing it.

1. Check out rbenv into `~/.rbenv`.

    ~~~ sh
    $ git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
    ~~~

2. Add `~/.rbenv/bin` to your `$PATH` for access to the `rbenv`
   command-line utility.

    ~~~ sh
    $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    ~~~

    **Ubuntu Desktop note**: Modify your `~/.bashrc` instead of `~/.bash_profile`.

    **Zsh note**: Modify your `~/.zshrc` file instead of `~/.bash_profile`.

3. Add `rbenv init` to your shell to enable shims and autocompletion.

    ~~~ sh
    $ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    ~~~

    _Same as in previous step, use `~/.bashrc` on Ubuntu, or `~/.zshrc` for Zsh._

4. Restart your shell so that PATH changes take effect. (Opening a new
   terminal tab will usually do it.) Now check if rbenv was set up:

    ~~~ sh
    $ type rbenv
    #=> "rbenv is a function"
    ~~~

5.  Install
[ruby-build](https://github.com/sstephenson/ruby-build),
which provides the
`rbenv install` command that simplifies the process of
installing new Ruby versions:

git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

Now you need to install ruby. Go to the 
[Ruby Downloads Page](https://www.ruby-lang.org/en/downloads/)
to find out what the current stable version is. As of 3/30/2014 it is
2.1.1 so I will use that in further examples, but substitute the current
stable version for 2.1.1 in what follows.

To install this version of ruby in rbenv, type

    rbenv install 2.1.1

Then, to make this the only version of ruby that you will use, type:

    rbenv global 2.1.1

If you want to use different versions of ruby in different contexts, read the
[rbenv page](https://github.com/sstephenson/rbenv)
for more information.


#### Installing Necessary Ruby Packages

Ruby packages are called gems and `gem` is the program used to install them.

After installing ruby as above, install needed gems as follows:

    gem install --no-ri --no-rdoc sqlite3 mysql sinatra shotgun


#### Running the server

Get the sqlite3 database  (ahtest.sqlite3) from 

    rhino02:/loc/no-backup/dtenenba/ahtest.sqlite3

Copy it to the same directory where this README file lives.

Set the environment variable that tells us which 
type of database you are using:

    export AHS_DATABASE_TYPE=sqlite

You could set it to `mysql` if you were using mysql. 

Now `cd` to the same directory as this README and do:

    shotgun app.rb

It will say:

    == Shotgun/WEBrick on http://127.0.0.1:9393/
    [2014-04-21 16:24:05] INFO  WEBrick 1.3.1
    [2014-04-21 16:24:05] INFO  ruby 2.1.1 (2014-02-24) [x86_64-darwin13.0]
    [2014-04-21 16:24:05] INFO  WEBrick::HTTPServer#start: pid=1156 port=9393


So you can open a web browser to 
[http://127.0.0.1:9393/](http://127.0.0.1:9393/) 

