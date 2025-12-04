# FDM/Resin Printer Support Implementation Plan

**Target**: Add full FDM and Resin printer technology support to the authenticated CalcuMake app

**Date**: December 4, 2025
**Status**: Planning Phase

---

## Executive Summary

The CalcuMake app currently assumes all printers are FDM (filament-based). This plan outlines adding comprehensive support for Resin (SLA/DLP/MSLA) printers alongside FDM, enabling users to:

1. Create printers with specific technology (FDM or Resin)
2. Store materials appropriate to each technology
3. Calculate costs accurately for both printer types
4. Use pre-populated "Common Printers" database from the JS calculator

---

## Current State Analysis

### ✅ What Works Well
- **Multi-plate architecture**: Proven scalable (up to 10 plates)
- **Flexible cost calculation**: Polymorphic methods easy to extend
- **Modal pattern**: Already supports dynamic printer/filament creation
- **Technology-agnostic Plate model**: No hardcoded FDM assumptions
- **Nested attributes**: PlateFilament join table handles complexity well

### ❌ Current Limitations
- **No printer technology field**: All printers assumed FDM
- **FDM-only Filament model**: Diameter, temperature, spool-based fields
- **Weight-based calculations only**: No volume support for resin
- **UI assumes filament**: Forms don't adapt to printer type

---

## Architecture Decision: Material Model Strategy

### Option A: Single Polymorphic Material Model ✅ **RECOMMENDED**
**Approach**: Extend Filament model → rename to `Material`, add `technology` enum

**Pros**:
- Leverages existing associations and cost calculation logic
- Single materials dropdown in UI
- Simpler codebase (no STI or separate models)
- Consistent API for plate_materials

**Cons**:
- More conditional logic in model
- Some fields irrelevant depending on technology (acceptable with conditionals)

**Implementation**:
```ruby
# Migration
rename_table :filaments, :materials
rename_table :plate_filaments, :plate_materials

add_column :materials, :technology, :integer, default: 0 # enum: fdm, resin
add_column :materials, :volume_ml, :decimal # For resin
add_column :materials, :price_per_liter, :decimal # For resin
# Keep existing FDM fields, make conditional
```

### Option B: Separate Models (NOT Recommended)
**Approach**: Keep Filament, create ResinMaterial
- Would require polymorphic plate_materials association
- Doubles controller/view logic
- More complex to maintain

---

## Implementation Phases

### **Phase 1: Database & Model Foundation** (Day 1)

#### 1.1 Add Printer Technology
```ruby
# Migration: AddTechnologyToPrinters
add_column :printers, :technology, :integer, default: 0, null: false
add_index :printers, :technology

# Enum values:
# 0 = fdm (default for existing data)
# 1 = resin
# (Future: 2 = sls, 3 = multi_material)
```

**Model Changes**:
```ruby
# app/models/printer.rb
enum technology: { fdm: 0, resin: 1 }

validates :technology, presence: true
```

#### 1.2 Extend Materials Model
```ruby
# Migration: RenameFilamentsToMaterials
rename_table :filaments, :materials
rename_table :plate_filaments, :plate_materials

# Migration: AddResinFieldsToMaterials
add_column :materials, :technology, :integer, default: 0, null: false
add_column :materials, :volume_ml, :decimal # For resin volume
add_column :materials, :price_per_liter, :decimal # For resin cost
add_column :materials, :cure_time_seconds, :integer # For resin
add_column :materials, :support_material_cost, :decimal # For resin

add_index :materials, :technology
add_index :materials, [:user_id, :technology]

# Make FDM-specific fields conditional (don't require for resin)
change_column_null :materials, :diameter, true
change_column_null :materials, :spool_weight, true
change_column_null :materials, :spool_price, true
```

**Model Updates**:
```ruby
# app/models/material.rb (renamed from filament.rb)
class Material < ApplicationRecord
  enum technology: { fdm: 0, resin: 1 }

  belongs_to :user, touch: true
  has_many :plate_materials, dependent: :destroy
  has_many :plates, through: :plate_materials

  # Validations conditional on technology
  with_options if: :fdm? do
    validates :diameter, presence: true, inclusion: { in: [1.75, 2.85, 3.0] }
    validates :spool_weight, presence: true, numericality: { greater_than: 0 }
    validates :spool_price, presence: true, numericality: { greater_than: 0 }
  end

  with_options if: :resin? do
    validates :volume_ml, presence: true, numericality: { greater_than: 0 }
    validates :price_per_liter, presence: true, numericality: { greater_than: 0 }
  end

  # Polymorphic cost calculation
  def cost_per_unit
    case technology
    when 'fdm'
      spool_price / spool_weight # Cost per gram
    when 'resin'
      price_per_liter / 1000.0 # Cost per ml
    end
  end

  def unit_label
    fdm? ? 'g' : 'mL'
  end
end

# app/models/plate_material.rb (renamed from plate_filament.rb)
class PlateMaterial < ApplicationRecord
  belongs_to :material
  belongs_to :plate

  # Renamed fields:
  # filament_weight → material_amount (works for both grams and mL)

  def total_cost
    base_cost = material_amount * material.cost_per_unit
    markup_multiplier = 1 + (markup_percentage / 100.0)
    base_cost * markup_multiplier
  end
end
```

#### 1.3 Data Migration
```ruby
# Migration: MigrateFDMDataToMaterials
def up
  # Set all existing printers to FDM
  Printer.update_all(technology: 0)

  # Set all existing materials to FDM
  Material.update_all(technology: 0)

  # Ensure data integrity
  Material.find_each do |material|
    material.update_columns(
      technology: 0,
      material_type: material.material_type || 'PLA'
    )
  end
end
```

---

### **Phase 2: Common Printers Database** (Day 1-2)

#### 2.1 Import Printer Profiles
Copy `public/printer_profiles.json` data into seed data or create admin interface.

```ruby
# db/seeds/common_printers.rb or lib/tasks/printers.rake
COMMON_PRINTERS = [
  {
    manufacturer: "Creality",
    model: "Ender 3 V3 SE",
    technology: :fdm,
    power_consumption: 100,
    cost: 199,
    category: "Budget FDM"
  },
  {
    manufacturer: "Elegoo",
    model: "Mars 5",
    technology: :resin,
    power_consumption: 70,
    cost: 179,
    category: "Budget Resin"
  },
  # ... 23 more printers
]

# Admin interface to let users "quick add" from common printers
# Or auto-suggest when creating new printer
```

#### 2.2 Printer Creation Enhancement
Add "Quick Add from Common Printers" feature:
- Dropdown or search interface
- Pre-fills all fields
- User can edit before saving
- Shows AI warning about estimated values

---

### **Phase 3: Controller & Permissions** (Day 2)

#### 3.1 Update Strong Params
```ruby
# app/controllers/printers_controller.rb
def printer_params
  params.require(:printer).permit(
    :name, :manufacturer, :technology, # ← Add technology
    :power_consumption, :cost, :payoff_goal_years,
    :daily_usage_hours, :repair_cost_percentage
  )
end

# app/controllers/materials_controller.rb (renamed from filaments_controller.rb)
def material_params
  params.require(:material).permit(
    :name, :brand, :material_type, :technology, # ← Add technology
    # FDM fields
    :diameter, :spool_weight, :spool_price,
    :print_temperature_min, :print_temperature_max,
    :heated_bed_temperature, :print_speed_max,
    # Resin fields
    :volume_ml, :price_per_liter, :cure_time_seconds,
    :support_material_cost,
    # Common fields
    :density, :color, :finish, :storage_temperature_max,
    :moisture_sensitive, :notes
  )
end

# app/controllers/print_pricings_controller.rb
def print_pricing_params
  params.require(:print_pricing).permit(
    # ... existing params ...
    plates_attributes: [
      :id, :printing_time_hours, :printing_time_minutes, :_destroy,
      plate_materials_attributes: [ # ← Renamed from plate_filaments_attributes
        :id, :material_id, :material_amount, :markup_percentage, :_destroy
      ]
    ]
  )
end
```

#### 3.2 Scopes & Filtering
```ruby
# app/models/printer.rb
scope :fdm, -> { where(technology: :fdm) }
scope :resin, -> { where(technology: :resin) }

# app/models/material.rb
scope :fdm, -> { where(technology: :fdm) }
scope :resin, -> { where(technology: :resin) }
scope :for_printer, ->(printer) { where(technology: printer.technology) }
```

---

### **Phase 4: View & Form Updates** (Day 2-3)

#### 4.1 Printer Form
```erb
<%# app/views/printers/_form.html.erb %>

<!-- Technology Toggle (similar to JS calculator) -->
<div class="mb-3">
  <label class="form-label fw-bold">Printer Technology</label>
  <div class="btn-group w-100" role="group">
    <%= f.radio_button :technology, :fdm, class: "btn-check", id: "printer_tech_fdm" %>
    <%= f.label :technology_fdm, "FDM (Filament)", class: "btn btn-outline-primary", for: "printer_tech_fdm" %>

    <%= f.radio_button :technology, :resin, class: "btn-check", id: "printer_tech_resin" %>
    <%= f.label :technology_resin, "Resin (SLA/DLP)", class: "btn btn-outline-primary", for: "printer_tech_resin" %>
  </div>
</div>

<!-- Rest of form fields (same for both technologies) -->
```

#### 4.2 Material Form
```erb
<%# app/views/materials/_form.html.erb %>

<!-- Technology Toggle -->
<div class="mb-3">
  <label class="form-label fw-bold">Material Technology</label>
  <div class="btn-group w-100" role="group">
    <%= f.radio_button :technology, :fdm, class: "btn-check", id: "material_tech_fdm",
        data: { action: "change->material-form#switchTechnology" } %>
    <%= f.label :technology_fdm, "FDM Filament", class: "btn btn-outline-primary", for: "material_tech_fdm" %>

    <%= f.radio_button :technology, :resin, class: "btn-check", id: "material_tech_resin",
        data: { action: "change->material-form#switchTechnology" } %>
    <%= f.label :technology_resin, "Resin", class: "btn btn-outline-primary", for: "material_tech_resin" %>
  </div>
</div>

<!-- FDM-Specific Fields -->
<div class="fdm-fields" data-material-form-target="fdmFields">
  <div class="row">
    <div class="col-md-4">
      <%= f.label :diameter, "Filament Diameter (mm)" %>
      <%= f.select :diameter, [1.75, 2.85, 3.0], {}, class: "form-select" %>
    </div>
    <div class="col-md-4">
      <%= f.label :spool_weight, "Spool Weight (g)" %>
      <%= f.number_field :spool_weight, class: "form-control" %>
    </div>
    <div class="col-md-4">
      <%= f.label :spool_price, "Spool Price" %>
      <%= f.number_field :spool_price, class: "form-control" %>
    </div>
  </div>
  <!-- Temperature fields, etc. -->
</div>

<!-- Resin-Specific Fields -->
<div class="resin-fields d-none" data-material-form-target="resinFields">
  <div class="row">
    <div class="col-md-4">
      <%= f.label :volume_ml, "Volume (mL)" %>
      <%= f.number_field :volume_ml, class: "form-control" %>
    </div>
    <div class="col-md-4">
      <%= f.label :price_per_liter, "Price per Liter" %>
      <%= f.number_field :price_per_liter, class: "form-control" %>
    </div>
    <div class="col-md-4">
      <%= f.label :cure_time_seconds, "Cure Time (sec)" %>
      <%= f.number_field :cure_time_seconds, class: "form-control" %>
    </div>
  </div>
</div>
```

#### 4.3 Print Pricing Form - Dynamic Material Selection
```erb
<%# app/views/print_pricings/_plate_material_fields.html.erb %>

<div class="plate-material-row">
  <div class="col-md-5">
    <label>Material</label>
    <%= f.select :material_id,
        options_from_collection_for_select(
          current_user.materials.for_printer(@print_pricing.printer),
          :id, :display_name, f.object.material_id
        ),
        { prompt: "Select Material" },
        class: "form-select",
        data: {
          action: "change->print-pricing-form#updateMaterialFields"
        } %>
  </div>

  <div class="col-md-3">
    <label>
      <span data-print-pricing-form-target="materialAmountLabel">
        <%= @print_pricing.printer&.resin? ? "Volume (mL)" : "Weight (g)" %>
      </span>
    </label>
    <%= f.number_field :material_amount, class: "form-control",
        data: { action: "input->print-pricing-form#calculate" } %>
  </div>

  <div class="col-md-2">
    <label>Markup %</label>
    <%= f.number_field :markup_percentage, value: 20, class: "form-control" %>
  </div>

  <div class="col-md-2">
    <button type="button" class="btn btn-danger" data-action="click->dynamic-list#remove">
      <i class="bi bi-trash"></i>
    </button>
  </div>
</div>
```

---

### **Phase 5: Stimulus Controllers** (Day 3)

#### 5.1 Material Form Controller
```javascript
// app/javascript/controllers/material_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fdmFields", "resinFields"]

  connect() {
    this.switchTechnology()
  }

  switchTechnology(event) {
    const technology = this.element.querySelector('input[name="material[technology]"]:checked')?.value

    if (technology === 'fdm') {
      this.fdmFieldsTarget.classList.remove('d-none')
      this.resinFieldsTarget.classList.add('d-none')
    } else if (technology === 'resin') {
      this.fdmFieldsTarget.classList.add('d-none')
      this.resinFieldsTarget.classList.remove('d-none')
    }
  }
}
```

#### 5.2 Print Pricing Form Controller
```javascript
// app/javascript/controllers/print_pricing_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["materialAmountLabel"]

  updateMaterialFields(event) {
    const materialSelect = event.target
    const technology = materialSelect.selectedOptions[0]?.dataset.technology

    // Update label
    if (this.hasMaterialAmountLabelTarget) {
      this.materialAmountLabelTarget.textContent =
        technology === 'resin' ? 'Volume (mL)' : 'Weight (g)'
    }

    this.calculate()
  }

  calculate() {
    // Existing calculation logic works - PlateMaterial#total_cost handles both
    // No changes needed to calculation formulas
  }
}
```

---

### **Phase 6: Tests** (Day 3-4)

#### 6.1 Model Tests
```ruby
# test/models/printer_test.rb
test "printer can be FDM or resin" do
  fdm_printer = printers(:ender_3)
  assert fdm_printer.fdm?
  refute fdm_printer.resin?

  resin_printer = printers(:elegoo_mars)
  assert resin_printer.resin?
  refute resin_printer.fdm?
end

# test/models/material_test.rb
test "FDM material calculates cost per gram" do
  filament = materials(:pla_black)
  assert_equal 0.025, filament.cost_per_unit # $25 / 1000g
end

test "resin material calculates cost per mL" do
  resin = materials(:elegoo_abs_like)
  assert_equal 0.040, resin.cost_per_unit # $40 / 1000mL
end

test "FDM material requires spool fields" do
  material = Material.new(technology: :fdm, name: "PLA")
  refute material.valid?
  assert_includes material.errors[:spool_weight], "can't be blank"
end

test "resin material requires volume fields" do
  material = Material.new(technology: :resin, name: "Resin")
  refute material.valid?
  assert_includes material.errors[:volume_ml], "can't be blank"
end
```

#### 6.2 System Tests
```ruby
# test/system/printers_test.rb
test "user can create FDM printer" do
  # ... test FDM creation
end

test "user can create resin printer" do
  # ... test resin creation
end

# test/system/print_pricings_test.rb
test "FDM print pricing shows filament weight fields" do
  # ... test FDM form
end

test "resin print pricing shows volume fields" do
  # ... test resin form
end

test "material dropdown filters by printer technology" do
  # ... test filtered materials
end
```

#### 6.3 Test Fixtures
```yaml
# test/fixtures/printers.yml
ender_3:
  name: "Creality Ender 3"
  manufacturer: "Creality"
  technology: fdm
  power_consumption: 350
  cost: 200

elegoo_mars:
  name: "Elegoo Mars 5"
  manufacturer: "Elegoo"
  technology: resin
  power_consumption: 70
  cost: 179

# test/fixtures/materials.yml
pla_black:
  name: "Black PLA"
  technology: fdm
  diameter: 1.75
  spool_weight: 1000
  spool_price: 25
  material_type: "PLA"

elegoo_abs_like:
  name: "Elegoo ABS-Like Resin"
  technology: resin
  volume_ml: 1000
  price_per_liter: 40
  material_type: "ABS-Like"
```

---

### **Phase 7: Translations** (Day 4)

Add keys to `config/locales/en/*.yml`:

```yaml
# config/locales/en/printers.yml
printers:
  technology:
    fdm: "FDM (Filament)"
    resin: "Resin (SLA/DLP)"
  form:
    select_technology: "Select Printer Technology"

# config/locales/en/materials.yml (renamed from filaments.yml)
materials:
  technology:
    fdm: "FDM Filament"
    resin: "Resin"
  form:
    volume_ml: "Volume (mL)"
    price_per_liter: "Price per Liter"
    cure_time: "Cure Time (seconds)"
    support_material_cost: "Support Material Cost"
```

Run `bin/sync-translations` to auto-translate to all 7 languages.

---

### **Phase 8: Data Migration & Deployment** (Day 4)

#### 8.1 Migration Safety
```ruby
# Ensure zero downtime
class AddTechnologyToPrinters < ActiveRecord::Migration[8.1]
  def change
    # Add with default, update existing data, then remove default
    add_column :printers, :technology, :integer, default: 0, null: false
    add_index :printers, :technology

    # Backfill is automatic with default: 0
  end
end
```

#### 8.2 Rollback Plan
- Keep old column names as aliases during transition
- Don't delete old code until new code is proven in production
- Use feature flags if deploying incrementally

---

## Risk Mitigation

### High Risk Areas
1. **Cost Calculation Changes**: PlateMaterial#total_cost must work for both
   - **Mitigation**: Comprehensive unit tests, fixture-based integration tests

2. **UI Conditional Logic**: Show/hide fields based on technology
   - **Mitigation**: Use Stimulus controllers for client-side reactivity, system tests

3. **Data Migration**: Renaming tables/columns without downtime
   - **Mitigation**: Use Rails migrations with safe column addition/removal pattern

4. **Existing User Data**: All current printers/filaments must stay FDM
   - **Mitigation**: Default to FDM (0) in enum, backfill migration

---

## Success Criteria

### Functional Requirements
- ✅ Users can create FDM and Resin printers
- ✅ Users can create FDM filaments and Resin materials
- ✅ Print pricing forms adapt to selected printer technology
- ✅ Material dropdowns filter by printer technology
- ✅ Cost calculations accurate for both technologies
- ✅ "Quick Add Common Printers" feature works
- ✅ All existing FDM data continues working

### Technical Requirements
- ✅ All 1,075+ tests pass
- ✅ Zero breaking changes to existing API
- ✅ Database migrations safe for production
- ✅ Translations complete for 7 languages
- ✅ System tests cover FDM and Resin workflows

---

## Timeline Estimate

**Total**: 4-5 days

- **Day 1**: Phase 1-2 (Database, models, common printers) - 6-8 hours
- **Day 2**: Phase 3-4 (Controllers, views, forms) - 6-8 hours
- **Day 3**: Phase 5-6 (Stimulus, tests) - 6-8 hours
- **Day 4**: Phase 7-8 (Translations, deployment) - 4-6 hours
- **Buffer**: Testing, bug fixes, refinement - 2-4 hours

---

## Future Enhancements (Post-Launch)

1. **Multi-Material FDM**: Multiple filaments per extruder (Prusa MMU, Bambu AMS)
2. **SLS Support**: Powder-based printing with reuse percentage
3. **Post-Processing Costs**: IPA baths, UV curing, support removal time
4. **Material Profiles**: Import from manufacturer (Bambu Studio, PrusaSlicer)
5. **Printer Maintenance Logs**: Track actual usage vs. estimates
6. **Material Inventory**: Track spool/bottle remaining amounts

---

## Notes

- This plan follows the same architecture as the successful JS calculator implementation
- Reuses proven patterns: polymorphic models, enum technology, conditional UI
- Maintains backward compatibility with existing FDM-only data
- Extensible for future printer technologies (SLS, multi-material, etc.)
