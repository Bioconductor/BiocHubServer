Sequel.migration do
  change do
    add_column :resources, :preparerclass, String
  end
end