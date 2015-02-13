Sequel.migration do
  change do
    add_column :rdatapaths, :dispatchclass, String
  end
end