# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_12_221421) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "cube"
  enable_extension "earthdistance"
  enable_extension "pg_catalog.plpgsql"

  create_table "favorite_golf_courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "golf_course_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["golf_course_id"], name: "index_favorite_golf_courses_on_golf_course_id"
    t.index ["user_id", "golf_course_id"], name: "index_favorite_courses_on_user_and_course", unique: true
    t.index ["user_id"], name: "index_favorite_golf_courses_on_user_id"
  end

  create_table "golf_courses", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "club_name"
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "external_api_id"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name", null: false
    t.string "phone"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "website"
    t.string "zip_code"
    t.index ["external_api_id"], name: "index_golf_courses_on_external_api_id", unique: true
    t.index ["latitude", "longitude"], name: "index_golf_courses_on_latitude_and_longitude"
    t.index ["name"], name: "index_golf_courses_on_name"
    t.index ["zip_code"], name: "index_golf_courses_on_zip_code"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_group_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "invite_code", null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_groups_on_invite_code", unique: true
    t.index ["owner_id", "name"], name: "index_groups_on_owner_id_and_name", unique: true
    t.index ["owner_id"], name: "index_groups_on_owner_id"
  end

  create_table "groups_tee_time_postings", id: false, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "tee_time_posting_id", null: false
    t.index ["group_id", "tee_time_posting_id"], name: "index_groups_tee_time_postings_on_group_and_posting", unique: true
    t.index ["group_id"], name: "index_groups_tee_time_postings_on_group_id"
    t.index ["tee_time_posting_id", "group_id"], name: "index_groups_tee_time_postings_on_posting_and_group"
    t.index ["tee_time_posting_id"], name: "index_groups_tee_time_postings_on_tee_time_posting_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "spots_reserved", null: false
    t.bigint "tee_time_posting_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tee_time_posting_id"], name: "index_reservations_on_tee_time_posting_id"
    t.index ["user_id", "tee_time_posting_id"], name: "index_reservations_on_user_id_and_tee_time_posting_id", unique: true
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tee_time_postings", force: :cascade do |t|
    t.integer "available_spots", default: 0
    t.string "course_name", null: false
    t.datetime "created_at", null: false
    t.bigint "golf_course_id"
    t.text "notes"
    t.datetime "tee_time", null: false
    t.integer "total_spots"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["golf_course_id"], name: "index_tee_time_postings_on_golf_course_id"
    t.index ["tee_time"], name: "index_tee_time_postings_on_tee_time"
    t.index ["user_id", "tee_time"], name: "index_tee_time_postings_on_user_id_and_tee_time"
    t.index ["user_id"], name: "index_tee_time_postings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "google_id"
    t.decimal "handicap", precision: 4, scale: 1
    t.string "home_zip_code"
    t.string "name"
    t.string "password_digest"
    t.integer "preferred_radius_miles", default: 25
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "venmo_handle"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["google_id"], name: "index_users_on_google_id", unique: true
    t.index ["home_zip_code"], name: "index_users_on_home_zip_code"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "favorite_golf_courses", "golf_courses"
  add_foreign_key "favorite_golf_courses", "users"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "users", column: "owner_id"
  add_foreign_key "groups_tee_time_postings", "groups"
  add_foreign_key "groups_tee_time_postings", "tee_time_postings"
  add_foreign_key "reservations", "tee_time_postings", on_delete: :cascade
  add_foreign_key "reservations", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "tee_time_postings", "golf_courses"
  add_foreign_key "tee_time_postings", "users"
end
