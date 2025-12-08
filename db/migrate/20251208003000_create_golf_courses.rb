class CreateGolfCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :golf_courses do |t|
      t.string :name, null: false
      t.string :club_name
      t.string :address
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :external_api_id
      t.string :phone
      t.string :website
      t.text :description

      t.timestamps
    end

    add_index :golf_courses, :external_api_id, unique: true
    add_index :golf_courses, [:latitude, :longitude]
    add_index :golf_courses, :zip_code
    add_index :golf_courses, :name
  end
end
