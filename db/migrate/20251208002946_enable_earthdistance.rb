class EnableEarthdistance < ActiveRecord::Migration[8.1]
  def up
    enable_extension 'cube' unless extension_enabled?('cube')
    enable_extension 'earthdistance' unless extension_enabled?('earthdistance')
  end

  def down
    disable_extension 'earthdistance'
    disable_extension 'cube'
  end
end
