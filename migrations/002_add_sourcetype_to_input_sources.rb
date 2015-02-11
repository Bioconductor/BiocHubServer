Sequel.migration do
  change do
    add_column :input_sources, :sourcetype, String
  end
end