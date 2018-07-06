Bioconductor Hub Server
========================
Updated: 06-27-2018


Bioconductor currently maintains two Hub resources for the project:
[AnnotationHub][] and [ExperimentHub][]. This repository provides the needed set
up to create a local hub with similar structure to the Bioconductor hubs. The
backend database created will be a clean .sqlite3 that resources can be viewed
and added utilizing the R Hub interface provided through AnnotationHub.

[AnnotationHub]: https://bioconductor.org/packages/AnnotationHub/
[ExperimentHub]: https://bioconductor.org/packages/ExperimentHub/

The hub code requires an sqlite3 database but provides utiliy to update/mirror
a mysql database. Please see the appropiate instructions for desired database
backend. We recommend simply using sqlite3.

Pick a database backend:

* [sqlite3](#sqlite3)

* [MySQL](#mysql)


<h2 id="sqlite3">sqlite3</h2>

### How to install

#### Clone this repository

Via SSH:

    git clone git@github.com:Bioconductor/BiocHubServer.git

Via Http:

    git clone https://github.com/Bioconductor/BiocHubServer.git

#### Installing System Dependencies

1. Make sure you have sqlite3 installed.

    sudo apt-get install libsqlite3

2. Install Ruby and the needed libraries (**IMPORTANT!!! follow link below**)

* [Install ruby and needed libraries](#ruby)

  Do not move foward until following the instructions at the link above!

<a name="sqlitecont"></a>

### Setting Up Own Local Database

#### Create a config.yml file

In the top level of the cloned repository create a config.yml.  There is a
provided config.yml.example. The main entries of the config file for local use
are:
```
dbname: "mydatabase"
dbtype: "sqlite"
```
The `dbtype` should always be `sqlite` when using a sqlite3 database backend.
The `dbname` is the name you will call your database. If copying the
config.yml.example file provided please remove the mysql specific entries!
The file should only contain dbname and dbtype.


#### Create your database

This will create an empty database for utilization.  If this is run, whatever
the name of the database in the config.yml, if it already exists is destroyed
and an empty database will remain. Please open the schema_sequel.rb file and
comment out the line `require 'mysql2'` so it reads `#require 'mysql2`.

```
ruby schema_sequel.rb
```

There were updates to the schema after implementation in Bioconductor so a
migration will also need to be run

```
sequel -m migrations/ sqlite:///<Full local path to sqlite3 database>/mydatabase.sqlite3

```

#### Start your server

Please open the app.rb file and comment out the line `require 'mysql2'` so it reads `#require 'mysql2`.
Now `cd` to the same directory as this README and do:

    shotgun app.rb

It will say:

    == Shotgun/WEBrick on http://127.0.0.1:9393/
    [2014-04-21 16:24:05] INFO  WEBrick 1.3.1
    [2014-04-21 16:24:05] INFO  ruby 2.1.1 (2014-02-24) [x86_64-darwin13.0]
    [2014-04-21 16:24:05] INFO  WEBrick::HTTPServer#start: pid=1156 port=9393


So you can open a web browser to
[http://127.0.0.1:9393/](http://127.0.0.1:9393/)

### Viewing and Adding Resources in R

The server must be running in order to utilize the Hub in R.  Navigate to the
cloned repository and run

       shotgun app.rb

In separate terminal window, start R and proceed with either of the two tasks.

#### Viewing Hub

The Hub will be accessible through the Hub infastructure in [AnnotationHub][].
It will be required to set up your own Hub class, and class cache method, that
relates to your database.


```
library(AnnotationHub)
# The class must be the same name as your database (that you specified in config)
setClass("mydatabase", contains = "Hub")
LocalHub <- function(...,
	 hub="http://127.0.0.1:9393",
	 cache="/home/lori/.MyBiocHub",  # where resources are downloaded/cached
	 proxy=NULL,
	 localHub=FALSE){
	 .Hub("mydatabase", hub, cache, proxy, localHub, ...)
}
hub <- LocalHub()


setMethod("cache", "mydatabase",
    function(x, ...) {
	callNextMethod(x,
		       cache.root=".MyBiocHub",
		       proxy=NULL,
		       max.downloads=10)
    }
)

# You can now use the built in Hub functions provided
hub
length(hub)
hub[1]
hub[[1]]
```


#### Adding Resources Hub

Adding Resources to the Hub is accomplished through infastructure in
[AnnotationHubData][] or [ExperimentHubData][].

[AnnotationHubData]: https://bioconductor.org/packages/AnnotationHubData/
[ExperimentHubData]: https://bioconductor.org/packages/ExperimentHubData/
[Creating AnnotationHub Package]: http://bioconductor.org/packages/release/bioc/vignettes/AnnotationHub/inst/doc/CreateAnAnnotationPackage.html
[Creating ExperimentHub Package]: https://bioconductor.org/packages/release/bioc/vignettes/ExperimentHub/inst/doc/CreateAnExperimentHubPackage.html

There are a number of built in on the fly applications for adding resources but
they best know and well documented way is to set up a package like structure with the required
DESCRIPTION and metadata.csv files as described in [Creating AnnotationHub Package][] or [Creating ExperimentHub Package][]

Remember the server must be running!

```
library(AnnotationHubData)  # or library(ExperimentHubData)
options(AH_SERVER_POST_URL="http://127.0.0.1:9393/resource")
options(ANNOTATION_HUB_URL="http://127.0.0.1:9393")
# run the appropriate makeMetadata function (makeExperimentHubMetadata for Experiment Hub Like Packages)
meta = makeAnnotationHubMetadata("<Path to Annotation Hub Like Package>")
url <- getOption("AH_SERVER_POST_URL")
pushMetadata(meta[[1]], url)

# The data is now added
# If you had your hub resource loaded as described in the previous section you
# could reload and see the newly added resource

hub <- LocalHub()
hub
```


<h2 id="mysql">MySQL</h2>

### How to install

#### Clone this repository

Via SSH:

    git clone git@github.com:Bioconductor/BiocHubServer.git

Via Http:

    git clone https://github.com/Bioconductor/BiocHubServer.git

#### Installing System Dependencies

1. Make sure you have mysql and sqlite3 (with headers) installed.

    sudo apt-get install libsqlite3 mysql-server libmysqlclient


2. Install Ruby and the needed libraries (**IMPORTANT!!! follow link below**)

* [Install ruby and needed libraries](#ruby)

  Do not move foward until following the instructions at the link above!


<a name="mysqlcont"></a>

### Setting Up Own Local Database

#### Create a config.yml file

In the top level of the cloned repository create a config.yml.  There is a
provided config.yml.example. The main entries of the config file for local use
are:
```
dbname: "mydatabase"
dbtype: "mysql"
mysql_url: mysql2://lori:supersecretpw@localhost/mydatabase
	# a user (lori) and password (supersecretpw) with access to your database (mydatabase)
```

The `dbtype` should always be `mysql` when using a mysql database backend. The
Hub functions require a `sqlite3` database so users opting for `mysql` will
have to run additional functions documented later this instruction manual to
keep the mysql and sqlite3 database in sync. The `dbname` is the name you
would like to call your database. The `mysql_url` is the url to the mysql
database with appropriate login information.


#### Create your database

The `mysql` approach assumes the user has created the empty database in `mysql` and
have some users with necessary permissions. Example code for this process:

```
# Log into mysql
mysql -u root -p

#create the database
CREATE DATABASE mydatabase;

# create any needed users with needed permission
CREATE USER lori;
GRANT ALL PRIVILEGES ON *.* TO 'lori'@'localhost' IDENTIFIED BY 'supersecretpw';

# exit out of mysql
exit
```

Now we initial the `mysql` database with schema and perform the migration

```
ruby schema_sequel.rb
sequel -m migrations/ mysql2://lori:supersecretpw@localhost/mydatabase
```

The tricky part with using `mysql` is the current R frontend expects a sqlite3 database.
The following will convert the `mysql` database to a sqlite3 database.

```
ruby convert_db.rb
```
Any time the `mysql` database is updated (resources added), this `ruby convert_db.rb`
MUST be run or the changes will not propagate.


#### Start your server

Now `cd` to the same directory as this README and do:

    shotgun app.rb

It will say:

    == Shotgun/WEBrick on http://127.0.0.1:9393/
    [2014-04-21 16:24:05] INFO  WEBrick 1.3.1
    [2014-04-21 16:24:05] INFO  ruby 2.1.1 (2014-02-24) [x86_64-darwin13.0]
    [2014-04-21 16:24:05] INFO  WEBrick::HTTPServer#start: pid=1156 port=9393


So you can open a web browser to
[http://127.0.0.1:9393/](http://127.0.0.1:9393/)

### Viewing and Adding Resources in R

The server must be running in order to utilize the Hub in R.  Navigate to the
cloned repository and run

       shotgun app.rb

In separate terminal window, start R and proceed with either of the two tasks.

#### Viewing Hub

The Hub will be accessible through the Hub infastructure in [AnnotationHub][].
It will be required to set up your own Hub class, and class cache method, that
relates to your database.


```
library(AnnotationHub)
# The class must be the same name as your database (that you specified in config)
setClass("mydatabase", contains = "Hub")
LocalHub <- function(...,
	 hub="http://127.0.0.1:9393",
	 cache="/home/lori/.MyBiocHub",  # where resources are downloaded/cached
	 proxy=NULL,
	 localHub=FALSE){
	 .Hub("mydatabase", hub, cache, proxy, localHub, ...)
}
hub <- LocalHub()


setMethod("cache", "mydatabase",
    function(x, ...) {
	callNextMethod(x,
		       cache.root=".MyBiocHub",
		       proxy=NULL,
		       max.downloads=10)
    }
)

# You can now use the built in Hub functions provided
hub
length(hub)
hub[1]
hub[[1]]
```


#### Adding Resources Hub

Adding Resources to the Hub is accomplished through infastructure in
[AnnotationHubData][] or [ExperimentHubData][].

There are a number of built in on the fly applications for adding resources but
they best know and well documented way is to set up a package like structure with the required
DESCRIPTION and metadata.csv files as described in [Creating AnnotationHub Package][] or [Creating ExperimentHub Package][]

Remember the server must be running!

```
library(AnnotationHubData)  # or library(ExperimentHubDatat)
options(AH_SERVER_POST_URL="http://127.0.0.1:9393/resource")
options(ANNOTATION_HUB_URL="http://127.0.0.1:9393")
# run the appropriate makeMetadata function  (makeExperimentHubMetdata for Experiment Hub Like Packages)
meta = makeAnnotationHubMetadata("<Path to Annotation Hub Like Package>")
url <- getOption("AH_SERVER_POST_URL")
pushMetadata(meta[[1]], url)

# The data is now added
# IMPORTANT:
# In a new terminal, run `ruby convert_db.rb`
# this is necessary to see the new resources
#

# See the previous section or if R session is still running reload the database
hub <- LocalHub()
hub
```









<h2 id="ruby">Installing Ruby and needed libraries</h2>


### Installing Ruby and needed libraries

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

5.  Install [ruby-build](https://github.com/sstephenson/ruby-build),
    which provides the `rbenv install` command that simplifies the
    process of installing new Ruby versions:

	git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

6.  Now you need to install ruby. Go to the
    [Ruby Downloads Page](https://www.ruby-lang.org/en/downloads/) to
    find out what the current stable version is. At the time of this
    documentation 6/22/2018, 2.5.0 was used for testing. Substitute the
    current stable version for 2.5.0 in what follows.

    To install this version of ruby in rbenv, type

	rbenv install 2.5.0

    Then, to make this the only version of ruby that you will use, type:

	rbenv global 2.5.0

    If you want to use different versions of ruby in different
    contexts, read the
    [rbenv page](https://github.com/sstephenson/rbenv) for more
    information.


#### Installing Necessary Ruby Packages

Ruby packages are called gems and `gem` is the program used to install them.

The `Gemfile` is like a `DESCRIPTION` file and describes the
package (gem) dependencies that are needed. this file is used by the
`bundler` gem. So install bundler:

    gem install bundler

Make sure you are in the top level of this cloned repository that contains the
Gemfile.

**NOTE:** If you are only using sqlite3, open the Gemfile and comment
out the line `gem "mysql2"`; it should read `#gem "mysql2"`.

**NOTE:** The provided Gemfile.lock contains the versions of modules that were
loaded when testing. To use the most updated versions of gems, remove the
Gemfile.lock. If you are using sqlite3 only, you will have to remove the mysql2 
entries from this file.


Tell bundler to read the Gemfile and install the packages specified there:

    bundle install


* [Back to sqlite instructions](#sqlitecont)
* [Back to mysql instructions](#mysqlcont)
