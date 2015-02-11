Sequel.migration do
  change do
    add_column :resources, :record_id, Integer
  end
end