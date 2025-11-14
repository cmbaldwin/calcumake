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

ActiveRecord::Schema[8.1].define(version: 2025_11_13_083604) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.text "address"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.text "notes"
    t.string "phone"
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "filaments", force: :cascade do |t|
    t.string "brand"
    t.string "color"
    t.datetime "created_at", null: false
    t.decimal "density", precision: 4, scale: 2
    t.decimal "diameter", precision: 4, scale: 2, default: "1.75"
    t.string "finish"
    t.integer "heated_bed_temperature"
    t.string "material_type", null: false
    t.boolean "moisture_sensitive", default: false
    t.string "name", null: false
    t.text "notes"
    t.integer "print_speed_max"
    t.integer "print_temperature_max"
    t.integer "print_temperature_min"
    t.decimal "spool_price", precision: 10, scale: 2
    t.decimal "spool_weight", precision: 8, scale: 2
    t.integer "storage_temperature_max"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["material_type"], name: "index_filaments_on_material_type"
    t.index ["user_id", "name"], name: "index_filaments_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_filaments_on_user_id"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "invoice_id", null: false
    t.string "line_item_type", default: "custom", null: false
    t.integer "order_position", default: 0, null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.decimal "total_price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "order_position"], name: "index_invoice_line_items_on_invoice_id_and_order_position"
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "client_id"
    t.text "company_address"
    t.string "company_email"
    t.string "company_name"
    t.string "company_phone"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.date "due_date"
    t.date "invoice_date", null: false
    t.string "invoice_number", null: false
    t.text "notes"
    t.text "payment_details"
    t.bigint "print_pricing_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["print_pricing_id"], name: "index_invoices_on_print_pricing_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "plate_filaments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "filament_id", null: false
    t.decimal "filament_weight", precision: 8, scale: 2, null: false
    t.decimal "markup_percentage", precision: 5, scale: 2, default: "20.0"
    t.bigint "plate_id", null: false
    t.datetime "updated_at", null: false
    t.index ["filament_id"], name: "index_plate_filaments_on_filament_id"
    t.index ["plate_id", "filament_id"], name: "index_plate_filaments_on_plate_id_and_filament_id", unique: true
    t.index ["plate_id"], name: "index_plate_filaments_on_plate_id"
  end

  create_table "plates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "print_pricing_id", null: false
    t.integer "printing_time_hours"
    t.integer "printing_time_minutes"
    t.datetime "updated_at", null: false
    t.index ["print_pricing_id"], name: "index_plates_on_print_pricing_id"
  end

  create_table "print_pricings", force: :cascade do |t|
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.decimal "final_price"
    t.string "job_name"
    t.decimal "listing_cost_percentage", precision: 5, scale: 2
    t.decimal "other_costs"
    t.decimal "payment_processing_cost_percentage", precision: 5, scale: 2
    t.decimal "postprocessing_cost_per_hour"
    t.integer "postprocessing_time_minutes"
    t.decimal "prep_cost_per_hour"
    t.integer "prep_time_minutes"
    t.bigint "printer_id"
    t.integer "times_printed", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "vat_percentage"
    t.index ["client_id"], name: "index_print_pricings_on_client_id"
    t.index ["printer_id"], name: "index_print_pricings_on_printer_id"
    t.index ["times_printed"], name: "index_print_pricings_on_times_printed"
    t.index ["user_id"], name: "index_print_pricings_on_user_id"
  end

  create_table "printers", force: :cascade do |t|
    t.decimal "cost", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.integer "daily_usage_hours", default: 8
    t.datetime "date_added", default: -> { "CURRENT_TIMESTAMP" }
    t.string "manufacturer"
    t.string "name", null: false
    t.integer "payoff_goal_years"
    t.decimal "power_consumption", precision: 8, scale: 2
    t.decimal "repair_cost_percentage", precision: 8, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_printers_on_user_id"
  end

  create_table "usage_trackings", force: :cascade do |t|
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "period_start", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["period_start"], name: "index_usage_trackings_on_period_start"
    t.index ["user_id", "resource_type", "period_start"], name: "index_usage_trackings_unique", unique: true
    t.index ["user_id"], name: "index_usage_trackings_on_user_id"
  end

  create_table "user_consents", force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.string "consent_type", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id", "consent_type", "created_at"], name: "index_consents_on_user_type_date"
    t.index ["user_id"], name: "index_user_consents_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.text "default_company_address"
    t.string "default_company_email"
    t.string "default_company_name"
    t.string "default_company_phone"
    t.string "default_currency", default: "USD"
    t.decimal "default_energy_cost_per_kwh", precision: 8, scale: 4, default: "0.12"
    t.decimal "default_filament_markup_percentage", precision: 5, scale: 2, default: "20.0"
    t.text "default_invoice_notes"
    t.decimal "default_listing_cost_percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "default_other_costs", precision: 10, scale: 2, default: "450.0"
    t.text "default_payment_details"
    t.decimal "default_payment_processing_cost_percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "default_postprocessing_cost_per_hour", precision: 10, scale: 2, default: "1000.0"
    t.integer "default_postprocessing_time_minutes", default: 10
    t.decimal "default_prep_cost_per_hour", precision: 10, scale: 2, default: "1000.0"
    t.integer "default_prep_time_minutes", default: 10
    t.decimal "default_vat_percentage", precision: 5, scale: 2, default: "20.0"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "locale"
    t.integer "next_invoice_number"
    t.string "plan", default: "free", null: false
    t.datetime "plan_expires_at"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "trial_ends_at"
    t.string "uid"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plan"], name: "index_users_on_plan"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
    t.index ["stripe_subscription_id"], name: "index_users_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "clients", "users"
  add_foreign_key "filaments", "users"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "print_pricings"
  add_foreign_key "invoices", "users"
  add_foreign_key "plate_filaments", "filaments"
  add_foreign_key "plate_filaments", "plates"
  add_foreign_key "plates", "print_pricings"
  add_foreign_key "print_pricings", "clients"
  add_foreign_key "print_pricings", "printers"
  add_foreign_key "print_pricings", "users"
  add_foreign_key "printers", "users"
  add_foreign_key "usage_trackings", "users"
  add_foreign_key "user_consents", "users"
end
