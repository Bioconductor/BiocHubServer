Sequel.migration do
  change do
    drop_column :input_sources, :sourcefile
    drop_column :rdatapaths, :rdatasize
    drop_column :rdatapaths, :rdatamd5
    drop_column :rdatapaths, :rdatalastmodifieddate
  end
end