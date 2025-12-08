class AddGolfCourseToTeeTimePostings < ActiveRecord::Migration[8.1]
  def change
    add_reference :tee_time_postings, :golf_course, foreign_key: true, null: true
  end
end
