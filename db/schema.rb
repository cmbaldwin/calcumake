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

ActiveRecord::Schema[8.0].define(version: 2025_10_21_074823) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.text "description", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "line_item_type", default: "custom", null: false
    t.integer "order_position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "order_position"], name: "index_invoice_line_items_on_invoice_id_and_order_position"
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "print_pricing_id", null: false
    t.bigint "user_id", null: false
    t.string "company_name"
    t.text "company_address"
    t.string "company_email"
    t.string "company_phone"
    t.text "payment_details"
    t.text "notes"
    t.string "invoice_number", null: false
    t.date "invoice_date", null: false
    t.date "due_date"
    t.string "status", default: "draft", null: false
    t.string "currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["print_pricing_id"], name: "index_invoices_on_print_pricing_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "plates", force: :cascade do |t|
    t.bigint "print_pricing_id", null: false
    t.integer "printing_time_hours"
    t.integer "printing_time_minutes"
    t.decimal "filament_weight"
    t.string "filament_type"
    t.decimal "spool_price"
    t.decimal "spool_weight"
    t.decimal "markup_percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["print_pricing_id"], name: "index_plates_on_print_pricing_id"
  end

  create_table "print_pricings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "job_name"
    t.integer "prep_time_minutes"
    t.decimal "prep_cost_per_hour"
    t.integer "postprocessing_time_minutes"
    t.decimal "postprocessing_cost_per_hour"
    t.decimal "other_costs"
    t.decimal "vat_percentage"
    t.decimal "final_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "printer_id"
    t.integer "times_printed", default: 0, null: false
    t.index ["printer_id"], name: "index_print_pricings_on_printer_id"
    t.index ["times_printed"], name: "index_print_pricings_on_times_printed"
    t.index ["user_id"], name: "index_print_pricings_on_user_id"
  end

  create_table "printers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "manufacturer"
    t.decimal "power_consumption", precision: 8, scale: 2
    t.decimal "cost", precision: 10, scale: 2
    t.integer "payoff_goal_years"
    t.datetime "date_added", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "daily_usage_hours", default: 8
    t.decimal "repair_cost_percentage", precision: 8, scale: 2, default: "0.0"
    t.index ["user_id"], name: "index_printers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "default_currency", default: "USD"
    t.decimal "default_energy_cost_per_kwh", precision: 8, scale: 4, default: "0.12"
    t.string "locale"
    t.boolean "admin", default: false, null: false
    t.string "default_company_name"
    t.text "default_company_address"
    t.string "default_company_email"
    t.string "default_company_phone"
    t.text "default_payment_details"
    t.text "default_invoice_notes"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "print_pricings"
  add_foreign_key "invoices", "users"
  add_foreign_key "plates", "print_pricings"
  add_foreign_key "print_pricings", "printers"
  add_foreign_key "print_pricings", "users"
  add_foreign_key "printers", "users"
end
