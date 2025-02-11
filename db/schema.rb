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

ActiveRecord::Schema[7.2].define(version: 2025_02_11_104328) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", null: false
    t.string "encrypted_password", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: true
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "email", null: false
    t.string "username"
    t.string "profile_image_url"
    t.boolean "is_deleted", default: false
    t.string "role", default: "一般"
    t.datetime "last_login_at"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["confirmed_at", "is_deleted"], name: "index_users_on_confirmed_at_and_is_deleted"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    t.check_constraint "char_length(username::text) <= 20", name: "check_username_length"
    t.check_constraint "confirmed_at IS NULL OR confirmed_at >= confirmation_sent_at", name: "check_confirmation_times"
    t.check_constraint "role::text = ANY (ARRAY['一般'::character varying, '管理者'::character varying, 'ゲスト'::character varying]::text[])", name: "check_role"
  end
end
