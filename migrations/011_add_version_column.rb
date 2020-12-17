basedir = File.dirname(__FILE__)

require_relative "../models.rb"

Sequel.migration do
  up do
    DB.add_column :rdatapaths, :version_id, String, :size => 255
    from(:rdatapaths).update(version_id: 'null')
  end

  down do
    DB.drop_column :rdatapaths, :version_id
  end
end
