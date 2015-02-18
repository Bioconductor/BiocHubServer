Sequel.migration do
  change do
    drop_column :resources, :rdataversion
  end
end