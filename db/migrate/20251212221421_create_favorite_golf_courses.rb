class CreateFavoriteGolfCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :favorite_golf_courses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :golf_course, null: false, foreign_key: true

      t.timestamps
    end

    # Prevent duplicate favorites
    add_index :favorite_golf_courses, [ :user_id, :golf_course_id ], unique: true, name: 'index_favorite_courses_on_user_and_course'
  end
end
