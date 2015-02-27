# invoke migrations with e.g.:
# sequel -m migrations/ sqlite:///Users/dante/dev/github/AnnotationHubServer3.0/ahtest.sqlite3
# this would seem even easier, but it doesn't work (or works on an ephemeral in-memory database):
# sequel -m migrations/ sqlite:annotationhub.sqlite3 
# you can interpolate $(pwd) into the command though:
# sequel -m migrations/ sqlite://$(pwd)/annotationhub.sqlite3
# for mysql do this:
# sequel -m migrations/ mysql://username:password@host/dbname
# Add -E before the url for more logging/debugging info
Sequel.migration do
  up do
    # create_table(:test) do
    #   primary_key :id
    #   String :name, :null=>false
    # end
  end

  down do
    # drop_table(:test)
  end
end