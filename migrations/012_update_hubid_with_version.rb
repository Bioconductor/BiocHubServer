Sequel.migration do
  up do
    DB.run "Update resources set ah_id = CONCAT(ah_id, '.0')"
  end
  
  down do
    DB.run "update resources set ah_id = SUBSTRING_INDEX(ah_id, '.', 1)"
  end
 
end
