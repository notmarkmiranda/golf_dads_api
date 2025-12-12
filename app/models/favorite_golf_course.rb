class FavoriteGolfCourse < ApplicationRecord
  belongs_to :user
  belongs_to :golf_course

  validates :user_id, uniqueness: { scope: :golf_course_id, message: "has already favorited this course" }

  # Order by most recently favorited
  default_scope { order(created_at: :desc) }
end
