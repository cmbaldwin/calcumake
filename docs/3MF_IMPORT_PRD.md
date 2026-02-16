# 3MF File Import Feature - Product Requirements Document

## Executive Summary

The 3MF File Import feature enables users to automatically populate print pricing estimates by uploading 3MF files directly from their slicer software (PrusaSlicer, Cura, Chitubox, Lychee Slicer, etc.). This eliminates manual data entry, reduces errors, and creates a seamless workflow between slicing and pricing/quoting.

**Status**: Ready for Implementation
**Target Release**: Q1 2026
**Complexity**: Medium-High
**Estimated Effort**: 3-5 days

---

## Problem Statement

### Current Pain Points

1. **Manual Data Entry**: Users must manually transcribe print time, material weight/volume, and material type from slicer to CalcuMake
2. **Error-Prone**: Manual transcription leads to pricing errors and lost revenue
3. **Time-Consuming**: Each print pricing requires 2-5 minutes of data entry
4. **User Friction**: Context switching between slicer and pricing tool reduces workflow efficiency
5. **Competitive Disadvantage**: Other 3D print management tools offer slicer integration

### User Stories

**As a 3D printing business owner**, I want to:
- Upload a 3MF file from my slicer and have print time/materials automatically extracted
- Avoid manual data entry errors that lead to underpricing
- Save time when creating quotes for customers
- Support both FDM and resin printing workflows

**As a hobbyist printer**, I want to:
- Quickly calculate accurate costs without manual calculations
- Track my actual vs. estimated print times from slicer data
- Experiment with different slicer settings and see cost impacts immediately

---

## Goals and Success Criteria

### Primary Goals

1. **Automate Data Extraction**: Parse 3MF files to extract print time, material data, and technology type
2. **Support Multiple Slicers**: PrusaSlicer, Cura, Chitubox, Lychee Slicer (extensible for others)
3. **Handle Both Technologies**: FDM (filament) and Resin printing with appropriate data extraction
4. **Maintain Accuracy**: 95%+ accuracy for print time and material quantities
5. **User-Friendly Experience**: Clear upload UI, status feedback, error handling

### Success Metrics

- **Adoption**: 40%+ of active users use 3MF import within 30 days of launch
- **Time Savings**: 70%+ reduction in print pricing creation time
- **Accuracy**: <5% error rate in extracted data vs. manual entry
- **User Satisfaction**: 4.5+ star rating for feature in feedback
- **Support Burden**: <10 support tickets per month related to 3MF import

### Non-Goals (Out of Scope)

- Multi-plate detection from single 3MF file (future enhancement)
- Multi-material extraction (future enhancement)
- STL/OBJ file support (different feature)
- Thumbnail extraction (future enhancement)
- Real-time slicer integration/plugin (future feature)

---

## Technical Requirements

### Functional Requirements

#### FR1: File Upload
- Users can upload `.3mf` files up to 100MB via print pricing form
- File validation for correct format and extension
- Support drag-and-drop and traditional file picker
- Client-side validation before upload

#### FR2: Background Processing
- 3MF files process asynchronously via background job (SolidQueue)
- Status indicators: pending, processing, completed, failed
- Retry logic for transient failures (3 attempts)
- Timeout protection (max 30 seconds per file)

#### FR3: Data Extraction - Common Fields
- **Print Time**: Parse from seconds, HH:MM:SS, or human-readable formats
- **Layer Height**: Extract in millimeters
- **Material Technology**: Auto-detect FDM vs. Resin based on metadata

#### FR4: Data Extraction - FDM-Specific
- **Filament Weight**: Parse from grams, kilograms, or raw numbers
- **Material Type**: PLA, ABS, PETG, TPU, ASA, etc.
- **Nozzle Diameter**: Extruder nozzle size (0.4mm, 0.6mm, etc.)

#### FR5: Data Extraction - Resin-Specific
- **Resin Volume**: Parse from milliliters, liters, or raw numbers
- **Resin Type**: Standard, ABS-Like, Flexible, Tough, Water-Washable, etc.
- **Exposure Time**: Layer exposure time in seconds
- **Bottom Layers**: Number of base layers
- **Lift Height**: Z-axis lift distance after layer
- **Lift Speed**: Z-axis lift speed in mm/min

#### FR6: Material Matching
- Attempt to match extracted material type with user's existing filaments/resins
- Case-insensitive fuzzy matching on material_type/resin_type
- Fallback to first available material if no match
- Log warnings for failed matches

#### FR7: Data Application
- Update first plate with extracted data:
  - `material_technology` (fdm or resin)
  - `printing_time_hours` and `printing_time_minutes`
  - For FDM: Create/update PlateFilament with weight and matched filament
  - For Resin: Create/update PlateResin with volume and matched resin
- Recalculate print pricing automatically

#### FR8: Error Handling
- Store error message in `three_mf_import_error` field
- Display user-friendly error messages in UI
- Log detailed errors for debugging
- Provide guidance on common issues (e.g., "No matching filament found")

#### FR9: UI/UX
- File upload section in print pricing form (new/edit)
- Status badge showing import state
- Success message with extracted data summary
- Error display with actionable guidance
- Option to re-upload if import fails

### Non-Functional Requirements

#### NFR1: Performance
- File processing completes in <5 seconds for typical files (1-50MB)
- No blocking of main application thread during processing
- S3 upload completes in <10 seconds for 50MB files

#### NFR2: Reliability
- 99.9% successful parsing rate for supported slicers
- Automatic retry on transient failures
- Graceful degradation if metadata is partially missing

#### NFR3: Security
- File validation before processing (content type, extension, size)
- Sandbox processing in background job (no shell execution)
- User-scoped file access only
- Consider antivirus scanning for production (future)

#### NFR4: Scalability
- Support concurrent processing of multiple imports
- No memory leaks from ZIP/XML parsing
- Temporary files cleaned up after processing

#### NFR5: Internationalization
- All UI text translatable via i18n keys
- Support for locale-specific error messages
- Material type matching works across languages

---

## Architecture and Design

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          User Interface                      │
│  (Print Pricing Form with File Upload + Status Display)     │
└────────────────────────┬────────────────────────────────────┘
                         │ uploads .3mf file
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    PrintPricing Model                        │
│  - has_one_attached :three_mf_file                          │
│  - three_mf_import_status: string                           │
│  - three_mf_import_error: text                              │
│  - after_commit callback triggers job                       │
└────────────────────────┬────────────────────────────────────┘
                         │ enqueues job
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Process3mfFileJob                          │
│  (SolidQueue Background Job)                                 │
│  1. Download file to temp location                          │
│  2. Call ThreeMfParser.parse                                │
│  3. Apply metadata to PrintPricing/Plate                    │
│  4. Update status to completed/failed                       │
└────────────────────────┬────────────────────────────────────┘
                         │ delegates parsing
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     ThreeMfParser                            │
│  (Service Object)                                            │
│  1. Validate ZIP archive                                    │
│  2. Extract XML from 3D/3dmodel.model                       │
│  3. Parse metadata elements                                 │
│  4. Detect material technology (FDM/Resin)                  │
│  5. Return structured metadata hash                         │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
┌─────────┐     ┌──────────────┐     ┌──────────────┐     ┌───────────┐
│  User   │────▶│ Upload 3MF   │────▶│ ActiveStorage│────▶│ S3 Bucket │
└─────────┘     │   File       │     │    Save      │     └───────────┘
                └──────┬───────┘     └──────────────┘
                       │
                       │ after_commit
                       ▼
                ┌──────────────┐
                │ Enqueue Job  │
                │ (SolidQueue) │
                └──────┬───────┘
                       │
                       ▼
                ┌──────────────┐     ┌──────────────┐
                │ Download to  │────▶│ Parse 3MF    │
                │ Temp File    │     │ (ThreeMfParser)│
                └──────────────┘     └──────┬───────┘
                                            │
                                            ▼
                                     ┌──────────────┐
                                     │ Extract      │
                                     │ Metadata     │
                                     └──────┬───────┘
                                            │
                  ┌─────────────────────────┴─────────────────────────┐
                  │                                                   │
                  ▼                                                   ▼
           ┌──────────────┐                                  ┌──────────────┐
           │ FDM Metadata │                                  │Resin Metadata│
           │ - weight     │                                  │ - volume     │
           │ - material   │                                  │ - resin_type │
           │ - nozzle     │                                  │ - exposure   │
           └──────┬───────┘                                  └──────┬───────┘
                  │                                                   │
                  └─────────────────────────┬─────────────────────────┘
                                            │
                                            ▼
                                     ┌──────────────┐
                                     │ Update Plate │
                                     │ - tech type  │
                                     │ - print time │
                                     │ - materials  │
                                     └──────┬───────┘
                                            │
                                            ▼
                                     ┌──────────────┐
                                     │ Recalculate  │
                                     │ PrintPricing │
                                     └──────┬───────┘
                                            │
                                            ▼
                                     ┌──────────────┐
                                     │ Update Status│
                                     │ (completed)  │
                                     └──────────────┘
```

### Database Schema

#### New Columns on `print_pricings` Table

```ruby
class AddThreeMfImportToPrintPricings < ActiveRecord::Migration[8.1]
  def change
    add_column :print_pricings, :three_mf_import_status, :string
    add_column :print_pricings, :three_mf_import_error, :text
    add_index :print_pricings, :three_mf_import_status
  end
end
```

**Status Values**:
- `nil` or `"pending"` - Not yet processed
- `"processing"` - Currently being parsed
- `"completed"` - Successfully imported
- `"failed"` - Import failed with error

#### ActiveStorage Tables (Existing)

Uses existing ActiveStorage infrastructure:
- `active_storage_attachments` - Links 3MF file to PrintPricing
- `active_storage_blobs` - Stores file metadata and S3 key
- `active_storage_variant_records` - Not used for 3MF files

### File Structure

```
3mf-file.3mf (ZIP Archive)
├── _rels/
│   └── .rels                       # Relationship definitions
├── 3D/
│   └── 3dmodel.model               # Main model XML with metadata
├── Metadata/
│   └── model_metadata.xml          # Optional additional metadata
└── Thumbnails/                     # Optional preview images
    └── thumbnail.png
```

**XML Structure Example**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
  <!-- Metadata elements -->
  <metadata name="prusaslicer:print_time">7200</metadata>
  <metadata name="prusaslicer:filament_weight">125.5</metadata>
  <metadata name="prusaslicer:material_type">PLA</metadata>
  <metadata name="prusaslicer:layer_height">0.2</metadata>
  <metadata name="prusaslicer:nozzle_diameter">0.4</metadata>

  <!-- 3D model data -->
  <resources>
    <object id="1" type="model">
      <mesh>
        <vertices>
          <vertex x="0" y="0" z="0"/>
          <!-- ... more vertices ... -->
        </vertices>
        <triangles>
          <triangle v1="0" v2="1" v3="2"/>
          <!-- ... more triangles ... -->
        </triangles>
      </mesh>
    </object>
  </resources>
</model>
```

### Parser Logic

#### Time Parsing

```ruby
def parse_time_value(value)
  # Handles multiple formats:
  # - "7200" (seconds)
  # - "2h 15m 30s" (human readable)
  # - "02:15:30" (HH:MM:SS)

  return nil if value.blank?

  if value.match?(/^\d+$/)
    value.to_f / 60  # Convert seconds to minutes
  elsif value.match?(/(\d+)h\s*(\d+)m/)
    # Parse "2h 15m" format
  elsif value.match?(/(\d+):(\d+):(\d+)/)
    # Parse "HH:MM:SS" format
  end
end
```

#### Weight/Volume Parsing

```ruby
def parse_weight_value(value)
  # Handles:
  # - "125.5" (raw grams)
  # - "125.5g" (with unit)
  # - "0.1255kg" (kilograms)

  value.gsub(/[^\d.]/, "").to_f
end

def parse_volume_value(value)
  # Handles:
  # - "50" (raw ml)
  # - "50ml" (with unit)
  # - "0.05l" (liters)

  cleaned = value.gsub(/[^\d.]/, "").to_f
  cleaned * 1000 if value.downcase.include?("l")  # Convert liters to ml
end
```

#### Technology Detection

```ruby
def detect_material_technology
  # Heuristic based on metadata keys
  if @metadata[:resin_volume_ml] || @metadata[:exposure_time] ||
     @metadata[:resin_type] || @metadata.keys.any? { |k| k.to_s.include?("resin") }
    @metadata[:material_technology] = "resin"
  elsif @metadata[:filament_weight] || @metadata[:nozzle_diameter] ||
        @metadata.keys.any? { |k| k.to_s.include?("filament") }
    @metadata[:material_technology] = "fdm"
  else
    @metadata[:material_technology] = "fdm"  # Default to FDM
  end
end
```

### Slicer-Specific Metadata Keys

| Slicer         | Print Time Key           | Material Key              | Material Type Key    |
|----------------|--------------------------|---------------------------|----------------------|
| PrusaSlicer    | `estimated_printing_time`| `filament_weight`         | `material_type`      |
| Cura           | `time`                   | `material_weight`         | `material`           |
| Chitubox       | `print_time`             | `resin_volume`            | `resin_type`         |
| Lychee Slicer  | `print_time`             | `volume_ml`               | `resin_material`     |

---

## Implementation Plan

### Phase 1: Core Infrastructure (Day 1-2)

#### Task 1.1: Database Migration
```bash
bin/rails generate migration AddThreeMfImportToPrintPricings \
  three_mf_import_status:string \
  three_mf_import_error:text
```

**Checklist**:
- [ ] Create migration file
- [ ] Add index on `three_mf_import_status`
- [ ] Run migration locally
- [ ] Verify schema.rb updated

#### Task 1.2: Model Changes
**File**: `app/models/print_pricing.rb`

```ruby
class PrintPricing < ApplicationRecord
  has_one_attached :three_mf_file

  validates :three_mf_file, content_type: [
    "application/x-3mf",
    "application/vnd.ms-package.3dmanufacturing-3dmodel+xml",
    "application/zip"
  ], size: { less_than: 100.megabytes }

  after_commit :enqueue_3mf_processing, if: :three_mf_file_attached_and_pending?

  def three_mf_file_attached_and_pending?
    three_mf_file.attached? &&
    (three_mf_import_status.nil? || three_mf_import_status == "pending")
  end

  def three_mf_processing?
    three_mf_import_status == "processing"
  end

  def three_mf_completed?
    three_mf_import_status == "completed"
  end

  def three_mf_failed?
    three_mf_import_status == "failed"
  end

  private

  def enqueue_3mf_processing
    update_column(:three_mf_import_status, "pending")
    Process3mfFileJob.perform_later(id)
  end
end
```

**Checklist**:
- [ ] Add ActiveStorage attachment
- [ ] Add validation for file type and size
- [ ] Add after_commit callback
- [ ] Add status helper methods
- [ ] Test in Rails console

#### Task 1.3: Add rubyzip Gem
**File**: `Gemfile`

```ruby
# ZIP file handling for 3MF imports
gem "rubyzip"
```

```bash
bundle install
```

**Checklist**:
- [ ] Add gem to Gemfile
- [ ] Run bundle install
- [ ] Verify Gemfile.lock updated
- [ ] Test `require "zip"` in Rails console

### Phase 2: Parser Service (Day 2)

#### Task 2.1: Create ThreeMfParser Service
**File**: `app/services/three_mf_parser.rb`

**Structure**:
```ruby
class ThreeMfParser
  class ParseError < StandardError; end

  attr_reader :file_path, :metadata

  def initialize(file_path)
    @file_path = file_path
    @metadata = {}
  end

  def parse
    validate_file!
    extract_metadata
    extract_model_data
    detect_material_technology
    @metadata
  end

  private

  # Validation methods
  def validate_file!
  def valid_zip?

  # Extraction methods
  def extract_metadata
  def extract_core_metadata(zip_file)
  def extract_slicer_metadata(zip_file)
  def extract_prusa_metadata(doc, namespaces)
  def extract_cura_metadata(doc, namespaces)
  def extract_resin_metadata(doc, namespaces)
  def extract_model_data

  # Helper methods
  def find_main_model_entry(zip_file)
  def extract_metadata_field(doc, namespaces, field_name)
  def store_metadata(name, value)

  # Parsing methods
  def parse_time_value(value)
  def parse_weight_value(value)
  def parse_volume_value(value)
  def detect_material_technology
end
```

**Checklist**:
- [ ] Create service class with all methods
- [ ] Implement ZIP validation
- [ ] Implement metadata extraction
- [ ] Implement time/weight/volume parsing
- [ ] Implement technology detection
- [ ] Add comprehensive error handling
- [ ] Test with sample 3MF files

#### Task 2.2: Create Sample Test Files
**Directory**: `test/fixtures/files/`

**Checklist**:
- [ ] Create sample FDM 3MF (PrusaSlicer)
- [ ] Create sample FDM 3MF (Cura)
- [ ] Create sample Resin 3MF (Chitubox)
- [ ] Create invalid 3MF for error testing
- [ ] Document expected metadata for each file

### Phase 3: Background Job (Day 3)

#### Task 3.1: Create Process3mfFileJob
**File**: `app/jobs/process3mf_file_job.rb`

**Structure**:
```ruby
class Process3mfFileJob < ApplicationJob
  queue_as :default

  retry_on ThreeMfParser::ParseError, wait: 5.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(print_pricing_id)
    print_pricing = PrintPricing.find(print_pricing_id)

    # Update status
    print_pricing.update_column(:three_mf_import_status, "processing")

    # Download and parse
    temp_file = download_file(print_pricing)

    begin
      parser = ThreeMfParser.new(temp_file.path)
      metadata = parser.parse

      apply_metadata_to_pricing(print_pricing, metadata)

      print_pricing.update!(
        three_mf_import_status: "completed",
        three_mf_import_error: nil
      )
    rescue => e
      print_pricing.update!(
        three_mf_import_status: "failed",
        three_mf_import_error: e.message
      )
      raise
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  private

  def download_file(print_pricing)
  def apply_metadata_to_pricing(print_pricing, metadata)
  def apply_filament_data(plate, metadata)
  def apply_resin_data(plate, metadata)
  def find_or_suggest_filament(user, material_type)
  def find_or_suggest_resin(user, resin_type)
end
```

**Checklist**:
- [ ] Create job class
- [ ] Implement download logic
- [ ] Implement metadata application
- [ ] Implement material matching logic
- [ ] Add error handling and cleanup
- [ ] Test job execution locally

### Phase 4: UI Components (Day 3-4)

#### Task 4.1: Update Print Pricing Form
**File**: `app/views/print_pricings/_form.html.erb`

**Add section**:
```erb
<div class="card mb-4">
  <div class="card-header">
    <h5 class="mb-0">
      <i class="bi bi-file-earmark-arrow-up me-2"></i>
      <%= t('print_pricing.three_mf.import_title') %>
    </h5>
  </div>
  <div class="card-body">
    <%= form.file_field :three_mf_file,
        accept: ".3mf",
        class: "form-control",
        data: {
          controller: "file-upload-validator",
          file_upload_validator_max_size_value: 100 * 1024 * 1024,
          file_upload_validator_accepted_types_value: [".3mf"]
        } %>
    <div class="form-text">
      <%= t('print_pricing.three_mf.help_text') %>
    </div>

    <% if @print_pricing.persisted? && @print_pricing.three_mf_file.attached? %>
      <div class="mt-3">
        <%= render "three_mf_status", print_pricing: @print_pricing %>
      </div>
    <% end %>
  </div>
</div>
```

**Checklist**:
- [ ] Add file upload field with proper attributes
- [ ] Add help text and instructions
- [ ] Add status display section
- [ ] Style with Bootstrap classes
- [ ] Test responsiveness

#### Task 4.2: Create Status Partial
**File**: `app/views/print_pricings/_three_mf_status.html.erb`

```erb
<div class="alert <%= status_class(print_pricing) %>" role="alert">
  <div class="d-flex align-items-center">
    <div class="flex-grow-1">
      <strong><%= status_icon(print_pricing) %> <%= status_text(print_pricing) %></strong>

      <% if print_pricing.three_mf_completed? %>
        <p class="mb-0 mt-2 small">
          <%= t('print_pricing.three_mf.completed_message',
                time: print_pricing.total_printing_time_minutes,
                material: print_pricing.plates.first&.material_types) %>
        </p>
      <% elsif print_pricing.three_mf_failed? %>
        <p class="mb-0 mt-2 small text-danger">
          <%= print_pricing.three_mf_import_error %>
        </p>
      <% elsif print_pricing.three_mf_processing? %>
        <div class="spinner-border spinner-border-sm ms-2" role="status">
          <span class="visually-hidden">Processing...</span>
        </div>
      <% end %>
    </div>

    <% if print_pricing.three_mf_file.attached? %>
      <div>
        <%= link_to rails_blob_path(print_pricing.three_mf_file, disposition: "attachment"),
                    class: "btn btn-sm btn-outline-secondary" do %>
          <i class="bi bi-download"></i> Download
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

**Checklist**:
- [ ] Create status partial
- [ ] Add helper methods for icons/classes
- [ ] Add download button
- [ ] Test all status states
- [ ] Verify error display

#### Task 4.3: Create Stimulus Controller
**File**: `app/javascript/controllers/file_upload_validator_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    maxSize: Number,
    acceptedTypes: Array
  }

  connect() {
    this.element.addEventListener("change", this.validate.bind(this))
  }

  validate(event) {
    const file = event.target.files[0]

    if (!file) return

    // Check file size
    if (file.size > this.maxSizeValue) {
      alert(`File is too large. Maximum size is ${this.maxSizeValue / 1024 / 1024}MB`)
      event.target.value = ""
      return
    }

    // Check file extension
    const ext = `.${file.name.split('.').pop().toLowerCase()}`
    if (!this.acceptedTypesValue.includes(ext)) {
      alert(`Invalid file type. Please upload a .3mf file`)
      event.target.value = ""
      return
    }
  }
}
```

**Checklist**:
- [ ] Create Stimulus controller
- [ ] Implement file size validation
- [ ] Implement file type validation
- [ ] Add user-friendly error messages
- [ ] Test validation edge cases

### Phase 5: Internationalization (Day 4)

#### Task 5.1: Add Translation Keys
**File**: `config/locales/en/print_pricings.yml`

```yaml
en:
  print_pricing:
    three_mf:
      import_title: "Import from 3MF File"
      file_label: "Upload 3MF File"
      help_text: "Upload a 3MF file from your slicer (PrusaSlicer, Cura, Chitubox, etc.) to automatically import print time and material data."
      download: "Download File"
      status:
        pending: "Import Pending"
        processing: "Processing Import..."
        completed: "Import Successful"
        failed: "Import Failed"
      completed_message: "Successfully imported: %{time} minutes, %{material}"
      errors:
        invalid_format: "File must be a valid .3mf file"
        too_large: "File is too large (maximum 100MB)"
        parse_failed: "Unable to parse 3MF file. Please ensure it's a valid file from a supported slicer."
        no_material_match: "Could not find matching %{material_type} in your materials. Please create it first or select a different material."
```

**Checklist**:
- [ ] Add all translation keys to English
- [ ] Run `bin/sync-translations` to auto-translate
- [ ] Verify all 7 languages updated
- [ ] Test UI in multiple languages
- [ ] Update CLAUDE.md if needed

### Phase 6: Testing (Day 4-5)

#### Task 6.1: Unit Tests for Parser
**File**: `test/services/three_mf_parser_test.rb`

```ruby
require "test_helper"

class ThreeMfParserTest < ActiveSupport::TestCase
  test "parses valid PrusaSlicer 3MF file" do
    file_path = file_fixture("prusa_fdm_sample.3mf").to_s
    parser = ThreeMfParser.new(file_path)
    metadata = parser.parse

    assert_equal 120.0, metadata[:print_time]  # minutes
    assert_equal 75.5, metadata[:filament_weight]
    assert_equal "PLA", metadata[:material_type]
    assert_equal "fdm", metadata[:material_technology]
  end

  test "parses valid Chitubox resin 3MF file" do
    file_path = file_fixture("chitubox_resin_sample.3mf").to_s
    parser = ThreeMfParser.new(file_path)
    metadata = parser.parse

    assert_equal 180.0, metadata[:print_time]
    assert_equal 25.5, metadata[:resin_volume_ml]
    assert_equal "Standard", metadata[:resin_type]
    assert_equal "resin", metadata[:material_technology]
  end

  test "handles missing metadata gracefully" do
    file_path = file_fixture("minimal_3mf.3mf").to_s
    parser = ThreeMfParser.new(file_path)
    metadata = parser.parse

    assert_not_nil metadata
    assert_kind_of Hash, metadata
  end

  test "raises error for invalid file" do
    assert_raises(ThreeMfParser::ParseError) do
      parser = ThreeMfParser.new("/tmp/invalid.txt")
      parser.parse
    end
  end

  test "parses time in various formats" do
    # Test time parsing
  end

  test "parses weight in various units" do
    # Test weight parsing
  end

  test "parses volume in various units" do
    # Test volume parsing
  end
end
```

**Checklist**:
- [ ] Write 20+ test cases
- [ ] Test each slicer format
- [ ] Test error conditions
- [ ] Test parsing edge cases
- [ ] Achieve 100% code coverage

#### Task 6.2: Integration Tests for Job
**File**: `test/jobs/process3mf_file_job_test.rb`

```ruby
require "test_helper"

class Process3mfFileJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @printer = printers(:ender_3)
    @filament = filaments(:pla_white)
    @print_pricing = @user.print_pricings.create!(
      job_name: "Test Job",
      printer: @printer,
      units: 1
    )
    @print_pricing.plates.create!(
      printing_time_hours: 0,
      printing_time_minutes: 0
    )
  end

  test "successfully processes FDM 3MF file" do
    file = file_fixture("prusa_fdm_sample.3mf")
    @print_pricing.three_mf_file.attach(
      io: File.open(file),
      filename: "test.3mf",
      content_type: "application/x-3mf"
    )

    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    assert_equal "completed", @print_pricing.three_mf_import_status
    assert_nil @print_pricing.three_mf_import_error

    plate = @print_pricing.plates.first
    assert_equal "fdm", plate.material_technology
    assert plate.total_printing_time_minutes > 0
    assert plate.plate_filaments.any?
  end

  test "successfully processes resin 3MF file" do
    # Similar test for resin
  end

  test "handles parse errors and retries" do
    # Test retry logic
  end

  test "updates status to failed on error" do
    # Test error handling
  end

  test "matches material types correctly" do
    # Test material matching
  end
end
```

**Checklist**:
- [ ] Write 15+ job tests
- [ ] Test happy path for FDM and Resin
- [ ] Test error handling
- [ ] Test retry logic
- [ ] Test material matching

#### Task 6.3: System Tests
**File**: `test/system/three_mf_import_test.rb`

```ruby
require "application_system_test_case"

class ThreeMfImportTest < ApplicationSystemTestCase
  setup do
    sign_in users(:john)
  end

  test "user can upload 3MF file and see extracted data" do
    visit new_print_pricing_path

    fill_in I18n.t('print_pricing.job_name'), with: "Test Import"

    # Upload file
    file_path = file_fixture("prusa_fdm_sample.3mf")
    attach_file "3MF File", file_path

    click_button I18n.t('actions.create')

    # Should see pending status
    assert_text I18n.t('print_pricing.three_mf.status.pending')

    # Process background job
    perform_enqueued_jobs

    # Refresh page
    visit current_path

    # Should see completed status
    assert_text I18n.t('print_pricing.three_mf.status.completed')

    # Verify data was extracted
    within ".plate-card" do
      assert_text "2h 0m"  # Print time
      assert_text "75.5g"  # Filament weight
    end
  end

  test "shows error for invalid file" do
    # Test error display
  end

  test "shows error when no matching material found" do
    # Test material matching error
  end
end
```

**Checklist**:
- [ ] Write 10+ system tests
- [ ] Test complete user workflow
- [ ] Test error scenarios
- [ ] Test UI feedback
- [ ] Test across browsers

### Phase 7: Documentation and Deployment (Day 5)

#### Task 7.1: Create Feature Documentation
**File**: `docs/3MF_IMPORT_FEATURE.md`

**Checklist**:
- [x] Document feature overview
- [x] Document architecture
- [x] Document supported slicers
- [x] Document data flow
- [x] Document troubleshooting
- [x] Document future enhancements

#### Task 7.2: Update CLAUDE.md
**Add to CLAUDE.md**:
- [ ] Feature description in "Core Architecture"
- [ ] 3MF import workflow
- [ ] Testing guidelines
- [ ] Key files reference

#### Task 7.3: Create User Guide
**Location**: Blog article or help section

**Checklist**:
- [ ] Write step-by-step guide
- [ ] Add screenshots
- [ ] Add video tutorial (optional)
- [ ] Test with real users
- [ ] Gather feedback

#### Task 7.4: Deployment
**Checklist**:
- [ ] Merge feature branch to main
- [ ] Run `bin/ci` to verify all tests pass
- [ ] Deploy to production via Kamal
- [ ] Monitor logs for errors
- [ ] Test production upload with real files
- [ ] Monitor SolidQueue for job processing
- [ ] Check S3 for file storage

---

## Testing Strategy

### Test Coverage Goals

- **Unit Tests**: 100% coverage for parser and utility methods
- **Integration Tests**: 95% coverage for job and model interactions
- **System Tests**: 90% coverage for user workflows
- **Total**: 95%+ overall coverage

### Test Pyramid

```
        /\
       /  \      10 System Tests (E2E)
      /____\
     /      \
    / 30 Job \   30 Integration Tests (Jobs, Controllers)
   /  Tests   \
  /____________\
 /              \
/  50 Unit Tests \  50 Unit Tests (Parser, Models, Helpers)
/__________________\
```

### Test Files Structure

```
test/
├── services/
│   └── three_mf_parser_test.rb          (50 assertions)
├── jobs/
│   └── process3mf_file_job_test.rb      (30 assertions)
├── models/
│   └── print_pricing_test.rb            (Add 10 assertions)
├── controllers/
│   └── print_pricings_controller_test.rb (Add 5 assertions)
├── system/
│   └── three_mf_import_test.rb          (10 assertions)
└── fixtures/
    └── files/
        ├── prusa_fdm_sample.3mf
        ├── cura_fdm_sample.3mf
        ├── chitubox_resin_sample.3mf
        ├── lychee_resin_sample.3mf
        ├── minimal_3mf.3mf
        └── invalid_3mf.3mf
```

### Manual Testing Checklist

**Before Deployment**:
- [ ] Upload FDM 3MF from PrusaSlicer
- [ ] Upload FDM 3MF from Cura
- [ ] Upload Resin 3MF from Chitubox
- [ ] Upload Resin 3MF from Lychee Slicer
- [ ] Test file size limit (100MB+)
- [ ] Test invalid file types (.stl, .txt, etc.)
- [ ] Test corrupted 3MF file
- [ ] Test 3MF with missing metadata
- [ ] Test 3MF with no matching materials
- [ ] Test concurrent uploads (multiple users)
- [ ] Test background job retry logic
- [ ] Verify S3 storage and cleanup
- [ ] Test in all 7 supported languages

**Post-Deployment**:
- [ ] Monitor error rates in production logs
- [ ] Check SolidQueue dashboard for failed jobs
- [ ] Verify S3 bucket storage usage
- [ ] Collect user feedback
- [ ] Monitor support tickets

---

## Security Considerations

### Threat Model

| Threat | Mitigation |
|--------|------------|
| **Malicious ZIP bombs** | File size limit (100MB), processing timeout (30s) |
| **XXE attacks** | Nokogiri configured with noent: false, nonet: true |
| **Path traversal** | Validate ZIP entry paths before extraction |
| **Arbitrary code execution** | No eval/system calls, sandboxed background job |
| **User file access** | Scope files to authenticated user only |
| **DoS via large files** | Queue rate limiting, size limits, timeout |
| **Malware upload** | Consider ClamAV integration (future) |

### Security Checklist

- [x] File size validation (100MB max)
- [x] File type validation (.3mf extension + MIME type)
- [x] ZIP archive validation before parsing
- [x] User authentication required
- [x] User-scoped file access only
- [x] Background job sandboxing (no shell access)
- [x] Temporary file cleanup (ensure block)
- [x] Input sanitization for metadata values
- [x] No SQL injection in metadata application
- [x] Error messages don't leak sensitive info
- [ ] Consider virus scanning (ClamAV) for production
- [ ] Rate limiting on uploads (future)

### Secure Parsing Guidelines

```ruby
# ✅ GOOD: Safe XML parsing with Nokogiri
doc = Nokogiri::XML(xml_content) do |config|
  config.strict.nonet.noent
end

# ❌ BAD: Unsafe eval or shell execution
system("unzip #{file_path}")  # NEVER do this
eval(metadata_value)          # NEVER do this

# ✅ GOOD: Validate ZIP entry paths
zip_file.each do |entry|
  raise "Invalid path" if entry.name.include?("../")
end

# ✅ GOOD: Sanitize metadata before storage
@metadata[name.to_sym] = ActionController::Base.helpers.sanitize(value)
```

---

## Performance Considerations

### Expected Performance

| Metric | Target | Notes |
|--------|--------|-------|
| File upload time | <10s | 50MB file over 10Mbps connection |
| Processing time | <5s | Typical 3MF file (1-50MB) |
| Job queue latency | <30s | Time from upload to processing start |
| Memory usage | <200MB | Per job instance |
| S3 storage cost | <$0.01/file | At $0.023/GB/month |

### Optimization Strategies

1. **Lazy Loading**: Only download file when job runs, not on upload
2. **Streaming**: Use streaming download for large files
3. **Caching**: Cache parsed metadata for re-uploads (future)
4. **Compression**: 3MF files are already compressed (ZIP)
5. **Parallel Processing**: SolidQueue handles concurrent jobs
6. **Cleanup**: Immediate temp file deletion after processing

### Monitoring

**Key Metrics to Track**:
- Job success/failure rate
- Average processing time
- Queue depth and latency
- S3 storage usage and cost
- Error types and frequency
- User adoption rate

**Alerting Thresholds**:
- Job failure rate >5%
- Average processing time >10s
- Queue depth >100 jobs
- S3 storage >50GB

---

## Future Enhancements

### Phase 2 Features (Q2 2026)

1. **Real-time Status Updates**
   - Turbo Stream broadcasts for completion status
   - No page refresh required
   - Live progress indicator

2. **Multi-Plate Detection**
   - Parse multiple build plates from single 3MF
   - Auto-create multiple Plate records
   - Handle multi-object layouts

3. **Multi-Material Support**
   - Extract multiple filament types and weights
   - Support multi-extruder prints
   - Map to multiple PlateFilament records

4. **Thumbnail Extraction**
   - Extract embedded preview images from 3MF
   - Display in UI before processing
   - Store with ActiveStorage

5. **Slicer Auto-Detection**
   - Identify source slicer from metadata
   - Adapt parsing strategy per slicer
   - Display slicer info in UI

### Phase 3 Features (Q3 2026)

6. **Preview Mode**
   - Show extracted data before saving
   - Allow user to review and adjust
   - Confirm before applying to plate

7. **Auto-Material Creation**
   - Suggest creating new material if no match
   - Pre-fill form with extracted data
   - One-click material creation

8. **Advanced Metadata**
   - Support material settings
   - Infill percentage
   - Print speed
   - Temperature settings

9. **Batch Import**
   - Upload multiple 3MF files at once
   - Create multiple PrintPricing records
   - Bulk processing queue

10. **API Support**
    - REST API endpoints for 3MF upload
    - Webhook notifications on completion
    - Enable slicer plugin integration

### Long-term Vision (2027)

- **Slicer Plugins**: Native PrusaSlicer/Cura plugins that send directly to CalcuMake
- **Desktop App**: Electron app with local slicer integration
- **Smart Defaults**: ML-powered default selection based on extracted data
- **Historical Analysis**: Compare slicer estimates vs. actual print times
- **Pricing Optimization**: Suggest optimal pricing based on material/time

---

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Slicer metadata format changes** | Medium | High | Flexible parser, version detection, graceful degradation |
| **Parsing accuracy issues** | Medium | Medium | Extensive testing, user feedback loop, manual override |
| **User adoption low** | Low | High | In-app tutorials, blog posts, email campaigns |
| **Performance issues with large files** | Low | Medium | Size limits, timeouts, streaming |
| **S3 storage costs** | Low | Low | 100MB limit, automatic cleanup after 90 days |
| **Security vulnerabilities** | Low | High | Security audit, input validation, sandboxing |
| **Support burden** | Medium | Low | Good documentation, clear error messages |

---

## Success Criteria and Launch Plan

### Launch Readiness Checklist

**Technical**:
- [ ] All tests passing (100+ tests, 95%+ coverage)
- [ ] Security audit completed
- [ ] Performance benchmarks met (<5s processing)
- [ ] Documentation complete (user guide + developer docs)
- [ ] Error handling comprehensive
- [ ] Monitoring and alerting configured

**Product**:
- [ ] User testing completed (5+ real users)
- [ ] Feedback incorporated
- [ ] Help documentation published
- [ ] Support team trained
- [ ] Rollout plan defined

**Launch**:
- [ ] Deploy to production
- [ ] Monitor for 24 hours
- [ ] Announce via blog post
- [ ] Email users about new feature
- [ ] Collect feedback via in-app survey

### Post-Launch Metrics (30 days)

**Adoption**:
- Target: 40%+ of active users try feature
- Target: 25%+ use it regularly (3+ times)

**Satisfaction**:
- Target: 4.5+ star rating
- Target: <10 support tickets/month

**Performance**:
- Target: 95%+ success rate
- Target: <5s average processing time
- Target: <$50/month S3 costs

**Business Impact**:
- Reduced pricing errors: 50%+ reduction
- Time savings: 70%+ reduction in data entry
- User retention: 10%+ increase
- Premium upgrade: 5%+ increase (feature exclusive)

---

## Appendix

### A. File Format Specification

**3MF Core Specification**: https://github.com/3MFConsortium/spec_core
**3MF Consortium**: https://3mf.io/

### B. Supported Slicers

| Slicer | Version Tested | FDM | Resin | Notes |
|--------|----------------|-----|-------|-------|
| PrusaSlicer | 2.7+ | ✅ | ❌ | Excellent metadata |
| Cura | 5.0+ | ✅ | ❌ | Good metadata |
| Chitubox | 1.9+ | ❌ | ✅ | Resin-specific fields |
| Lychee Slicer | 4.0+ | ❌ | ✅ | Comprehensive resin data |
| Simplify3D | 5.0+ | ⚠️ | ❌ | Limited metadata |
| ideaMaker | 4.0+ | ⚠️ | ❌ | Minimal metadata |

Legend: ✅ Fully supported, ⚠️ Partial support, ❌ Not supported

### C. Technology Stack

- **Ruby**: 3.2+
- **Rails**: 8.1+
- **rubyzip**: Latest stable
- **nokogiri**: Latest stable (XML parsing)
- **activestorage**: Built-in Rails
- **solidqueue**: Background jobs
- **aws-sdk-s3**: S3 storage via Hetzner
- **turbo-rails**: UI updates (future)
- **stimulus**: Client-side validation

### D. References

- [ActiveStorage Guide](https://guides.rubyonrails.org/active_storage_overview.html)
- [SolidQueue Documentation](https://github.com/rails/solid_queue)
- [Rubyzip Documentation](https://github.com/rubyzip/rubyzip)
- [Nokogiri Documentation](https://nokogiri.org/)
- [3MF Specification](https://github.com/3MFConsortium/spec_core)

---

**Document Version**: 1.0
**Last Updated**: 2026-01-27
**Author**: Claude Code with Cody Baldwin
**Status**: Ready for Implementation
**Approval**: Pending

