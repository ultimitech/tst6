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

ActiveRecord::Schema[8.0].define(version: 2025_02_08_145424) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.string "role"
    t.boolean "active"
    t.integer "place"
    t.boolean "ci"
    t.string "status"
    t.integer "ccs"
    t.integer "vcs"
    t.integer "ct"
    t.integer "vt"
    t.integer "majtes"
    t.integer "tietes"
    t.integer "ccs_m"
    t.integer "ccs_k"
    t.integer "vcs_a"
    t.integer "vcs_c"
    t.integer "vcs_t"
    t.integer "vcs_p"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.date "dod"
    t.string "tod"
    t.string "dow"
    t.string "title"
    t.string "descriptor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "translations", force: :cascade do |t|
    t.string "lan"
    t.string "tran_title"
    t.string "descrip"
    t.integer "blkc"
    t.integer "subc"
    t.integer "senc"
    t.string "xcrip"
    t.boolean "li"
    t.date "pubdate"
    t.string "version"
    t.bigint "message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_translations_on_message_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin"
    t.integer "cur_assign_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "translations", "messages"
end
