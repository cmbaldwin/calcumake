# 3MF Import Feature - Implementation Plan

**Status**: Ready for Implementation
**Estimated Duration**: 3-5 days
**Complexity**: Medium-High
**Priority**: High
**Target Release**: Q1 2026

---

## Overview

This document provides a step-by-step implementation plan for the 3MF file import feature. It complements the PRD ([3MF_IMPORT_PRD.md](3MF_IMPORT_PRD.md)) with specific technical steps and commands.

---

## Prerequisites

Before starting implementation:

- [ ] Read [3MF_IMPORT_PRD.md](3MF_IMPORT_PRD.md) completely
- [ ] Review [3MF_IMPORT_FEATURE.md](3MF_IMPORT_FEATURE.md) from PR #42
- [ ] Understand current `Plate` and `PrintPricing` models
- [ ] Familiarize with ActiveStorage and SolidQueue
- [ ] Have sample 3MF files from PrusaSlicer, Cura, Chitubox

---

## Implementation Sequence

### Day 1: Core Infrastructure

#### Step 1: Create Feature Branch

```bash
git checkout -b feature/3mf-import-feature
```

#### Step 2: Database Migration

```bash
# Generate migration
bin/rails generate migration AddThreeMfImportToPrintPricings \
  three_mf_import_status:string \
  three_mf_import_error:text

# Edit migration to add index
```

**Edit**: `db/migrate/XXXXXX_add_three_mf_import_to_print_pricings.rb`

```ruby
class AddThreeMfImportToPrintPricings < ActiveRecord::Migration[8.1]
  def change
    add_column :print_pricings, :three_mf_import_status, :string
    add_column :print_pricings, :three_mf_import_error, :text
    add_index :print_pricings, :three_mf_import_status
  end
end
```

```bash
# Run migration
bin/rails db:migrate

# Verify schema
grep "three_mf" db/schema.rb
```

#### Step 3: Add rubyzip Gem

**Edit**: `Gemfile`

```ruby
# Add after other file handling gems
gem "rubyzip", "~> 2.3"
```

```bash
bundle install
bundle lock --add-platform x86_64-linux  # For Docker deployment

# Test gem loaded
bin/rails runner "require 'zip'; puts 'Rubyzip loaded successfully'"
```

#### Step 4: Update PrintPricing Model

**Edit**: `app/models/print_pricing.rb`

Add after existing `has_many` associations:

```ruby
has_one_attached :three_mf_file
```

Add after existing validations:

```ruby
validates :three_mf_file, content_type: [
  "application/x-3mf",
  "application/vnd.ms-package.3dmanufacturing-3dmodel+xml",
  "application/zip"
], size: { less_than: 100.megabytes }, if: -> { three_mf_file.attached? }
```

Add after existing callbacks:

```ruby
after_commit :enqueue_3mf_processing, if: :three_mf_file_attached_and_pending?
```

Add public methods:

```ruby
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
```

Add private method:

```ruby
private

def enqueue_3mf_processing
  update_column(:three_mf_import_status, "pending")
  Process3mfFileJob.perform_later(id)
end
```

**Test in console**:

```bash
bin/rails console
> pp = PrintPricing.first
> pp.three_mf_file.attach(io: File.open("test.3mf"), filename: "test.3mf")
> pp.three_mf_file.attached?
> pp.three_mf_file_attached_and_pending?
```

---

### Day 2: Parser Service

#### Step 5: Create Test Fixtures Directory

```bash
mkdir -p test/fixtures/files
```

#### Step 6: Create Sample 3MF Files

**Option A**: Export from slicers manually
- PrusaSlicer: Slice a model, export 3MF
- Cura: Slice a model, save as 3MF
- Chitubox: Slice a model, export 3MF

**Option B**: Create minimal test files programmatically

Create `test/fixtures/files/sample_fdm.3mf`:

```bash
# This will be a minimal 3MF with known metadata
# We'll create this programmatically in tests
```

#### Step 7: Create ThreeMfParser Service

```bash
touch app/services/three_mf_parser.rb
```

**Copy implementation from PR #42** branch:

```bash
git show origin/claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA:app/services/three_mf_parser.rb > app/services/three_mf_parser.rb
```

**Key sections to verify**:
- `ParseError` class defined
- `initialize(file_path)` method
- `parse` method (main entry point)
- `validate_file!` and `valid_zip?`
- `extract_metadata`, `extract_slicer_metadata`
- `extract_prusa_metadata`, `extract_cura_metadata`, `extract_resin_metadata`
- `parse_time_value`, `parse_weight_value`, `parse_volume_value`
- `detect_material_technology`
- `store_metadata` with normalization

**Test parser in console**:

```bash
bin/rails console
> require "zip"
> parser = ThreeMfParser.new("test/fixtures/files/sample_fdm.3mf")
> metadata = parser.parse
> pp metadata
```

---

### Day 3: Background Job

#### Step 8: Create Process3mfFileJob

```bash
bin/rails generate job Process3mfFile
```

**Edit**: `app/jobs/process3mf_file_job.rb`

Replace generated content with implementation from PR #42:

```bash
git show origin/claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA:app/jobs/process3mf_file_job.rb > app/jobs/process3mf_file_job.rb
```

**Key sections to verify**:
- `queue_as :default`
- `retry_on ThreeMfParser::ParseError, wait: 5.seconds, attempts: 3`
- `perform(print_pricing_id)` method
- `download_file(print_pricing)` - temp file handling
- `apply_metadata_to_pricing(print_pricing, metadata)` - main logic
- `apply_filament_data(plate, metadata)` - FDM
- `apply_resin_data(plate, metadata)` - Resin
- `find_or_suggest_filament(user, material_type)` - matching
- `find_or_suggest_resin(user, resin_type)` - matching
- Error handling with status updates
- Cleanup in `ensure` block

**Test job in console**:

```bash
bin/rails console
> pp = PrintPricing.first
> pp.three_mf_file.attach(io: File.open("test.3mf"), filename: "test.3mf")
> pp.save!
> Process3mfFileJob.perform_now(pp.id)
```

---

### Day 3-4: UI Components

#### Step 9: Add File Upload to Form

**Edit**: `app/views/print_pricings/_form.html.erb`

Add new section after existing form sections (around line 30-40):

```erb
<!-- 3MF File Import Section -->
<div class="card mb-4">
  <div class="card-header">
    <h5 class="mb-0">
      <i class="bi bi-file-earmark-arrow-up me-2"></i>
      <%= t('print_pricing.three_mf.import_title') %>
    </h5>
  </div>
  <div class="card-body">
    <div class="mb-3">
      <%= form.file_field :three_mf_file,
          accept: ".3mf",
          class: "form-control",
          data: {
            controller: "file-upload-validator",
            file_upload_validator_max_size_value: 100 * 1024 * 1024,
            file_upload_validator_accepted_types_value: [".3mf"].to_json
          } %>
      <div class="form-text">
        <%= t('print_pricing.three_mf.help_text') %>
      </div>
    </div>

    <% if @print_pricing.persisted? && @print_pricing.three_mf_file.attached? %>
      <div class="mt-3">
        <%= render "three_mf_status", print_pricing: @print_pricing %>
      </div>
    <% end %>
  </div>
</div>
```

#### Step 10: Create Status Partial

```bash
touch app/views/print_pricings/_three_mf_status.html.erb
```

**Content**:

```erb
<%# Status badge for 3MF import %>
<div class="alert <%= three_mf_status_class(@print_pricing) %> alert-dismissible fade show" role="alert">
  <div class="d-flex align-items-center">
    <div class="flex-grow-1">
      <strong>
        <%= three_mf_status_icon(@print_pricing) %>
        <%= three_mf_status_text(@print_pricing) %>
      </strong>

      <% if @print_pricing.three_mf_completed? %>
        <p class="mb-0 mt-2 small">
          <%= t('print_pricing.three_mf.completed_message',
                time: @print_pricing.total_printing_time_minutes,
                material: @print_pricing.plates.first&.material_types || "N/A") %>
        </p>
      <% elsif @print_pricing.three_mf_failed? %>
        <p class="mb-0 mt-2 small text-danger">
          <i class="bi bi-exclamation-triangle-fill me-1"></i>
          <%= @print_pricing.three_mf_import_error %>
        </p>
        <p class="mb-0 mt-2 small">
          <%= t('print_pricing.three_mf.retry_instructions') %>
        </p>
      <% elsif @print_pricing.three_mf_processing? %>
        <div class="d-inline-block ms-2">
          <div class="spinner-border spinner-border-sm" role="status">
            <span class="visually-hidden">Processing...</span>
          </div>
        </div>
      <% end %>
    </div>

    <% if @print_pricing.three_mf_file.attached? %>
      <div class="ms-3">
        <%= link_to rails_blob_path(@print_pricing.three_mf_file, disposition: "attachment"),
                    class: "btn btn-sm btn-outline-secondary",
                    title: t('print_pricing.three_mf.download') do %>
          <i class="bi bi-download"></i>
          <%= number_to_human_size(@print_pricing.three_mf_file.byte_size) %>
        <% end %>
      </div>
    <% end %>
  </div>
  <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
```

#### Step 11: Create Helper Methods

**Edit**: `app/helpers/print_pricings_helper.rb`

Add at the end:

```ruby
# 3MF Import Status Helpers

def three_mf_status_class(print_pricing)
  case print_pricing.three_mf_import_status
  when "completed"
    "alert-success"
  when "failed"
    "alert-danger"
  when "processing"
    "alert-info"
  else
    "alert-secondary"
  end
end

def three_mf_status_icon(print_pricing)
  case print_pricing.three_mf_import_status
  when "completed"
    content_tag(:i, "", class: "bi bi-check-circle-fill text-success me-2")
  when "failed"
    content_tag(:i, "", class: "bi bi-x-circle-fill text-danger me-2")
  when "processing"
    content_tag(:i, "", class: "bi bi-hourglass-split text-info me-2")
  else
    content_tag(:i, "", class: "bi bi-clock text-secondary me-2")
  end
end

def three_mf_status_text(print_pricing)
  t("print_pricing.three_mf.status.#{print_pricing.three_mf_import_status || 'pending'}")
end
```

#### Step 12: Create Stimulus Controller for Validation

```bash
touch app/javascript/controllers/file_upload_validator_controller.js
```

**Content**:

```javascript
import { Controller } from "@hotwired/stimulus"

// Validates file uploads before submission
export default class extends Controller {
  static values = {
    maxSize: Number,
    acceptedTypes: Array
  }

  connect() {
    this.element.addEventListener("change", this.validate.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("change", this.validate.bind(this))
  }

  validate(event) {
    const file = event.target.files[0]

    if (!file) return

    // Check file size
    if (this.maxSizeValue && file.size > this.maxSizeValue) {
      const maxSizeMB = Math.round(this.maxSizeValue / 1024 / 1024)
      alert(`File is too large. Maximum size is ${maxSizeMB}MB`)
      event.target.value = ""
      return false
    }

    // Check file extension
    if (this.acceptedTypesValue && this.acceptedTypesValue.length > 0) {
      const fileName = file.name.toLowerCase()
      const ext = `.${fileName.split('.').pop()}`

      if (!this.acceptedTypesValue.includes(ext)) {
        const acceptedList = this.acceptedTypesValue.join(", ")
        alert(`Invalid file type. Please upload one of: ${acceptedList}`)
        event.target.value = ""
        return false
      }
    }

    return true
  }
}
```

**Register controller** in `app/javascript/controllers/index.js` (if not auto-registered):

```javascript
import FileUploadValidatorController from "./file_upload_validator_controller"
application.register("file-upload-validator", FileUploadValidatorController)
```

---

### Day 4: Internationalization

#### Step 13: Add Translation Keys

**Edit**: `config/locales/en/print_pricings.yml`

Add new section after existing keys:

```yaml
en:
  print_pricing:
    # ... existing keys ...

    three_mf:
      import_title: "Import from 3MF File"
      file_label: "Upload 3MF File"
      help_text: "Upload a 3MF file from your slicer (PrusaSlicer, Cura, Chitubox, Lychee Slicer) to automatically import print time and material data. Maximum file size: 100MB."
      download: "Download File"
      retry_instructions: "Please check your file and try uploading again, or contact support if the issue persists."
      status:
        pending: "Import Pending"
        processing: "Processing Import..."
        completed: "Import Successful"
        failed: "Import Failed"
      completed_message: "Successfully imported: %{time} minutes print time using %{material}"
      errors:
        invalid_format: "File must be a valid .3mf file"
        too_large: "File is too large (maximum 100MB)"
        parse_failed: "Unable to parse 3MF file. Please ensure it's a valid file from a supported slicer (PrusaSlicer, Cura, Chitubox, Lychee Slicer)."
        no_material_match: "Could not find matching %{material_type} in your materials library. Please create it first or select a different material."
        no_metadata: "3MF file contains no printable metadata. Please ensure your slicer is configured to export metadata."
```

#### Step 14: Sync Translations

```bash
# Run translation sync to auto-translate to all 7 languages
bin/sync-translations

# Verify all locales updated
ls -lah config/locales/*.yml

# Spot-check Japanese translation
grep "three_mf" config/locales/ja.yml
```

---

### Day 4-5: Testing

#### Step 15: Create Parser Tests

```bash
touch test/services/three_mf_parser_test.rb
```

**Copy test implementation from PR #42**:

```bash
git show origin/claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA:test/services/three_mf_parser_test.rb > test/services/three_mf_parser_test.rb
```

**Verify test structure**:
- Tests for valid FDM 3MF (PrusaSlicer)
- Tests for valid FDM 3MF (Cura)
- Tests for valid Resin 3MF (Chitubox)
- Tests for missing metadata
- Tests for invalid files
- Tests for time parsing variations
- Tests for weight parsing variations
- Tests for volume parsing variations
- Tests for technology detection

**Run tests**:

```bash
bin/rails test test/services/three_mf_parser_test.rb
```

#### Step 16: Create Job Tests

```bash
touch test/jobs/process3mf_file_job_test.rb
```

**Copy test implementation from PR #42**:

```bash
git show origin/claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA:test/jobs/process3mf_file_job_test.rb > test/jobs/process3mf_file_job_test.rb
```

**Verify test structure**:
- Test successful FDM file processing
- Test successful Resin file processing
- Test status updates (pending → processing → completed)
- Test error handling and status update to failed
- Test retry logic
- Test material matching (exact, fuzzy, fallback)
- Test plate updates
- Test temp file cleanup

**Run tests**:

```bash
bin/rails test test/jobs/process3mf_file_job_test.rb
```

#### Step 17: Update Model Tests

**Edit**: `test/models/print_pricing_test.rb`

Add tests:

```ruby
test "should attach 3mf file" do
  print_pricing = print_pricings(:one)
  file = file_fixture("sample_fdm.3mf")

  print_pricing.three_mf_file.attach(
    io: File.open(file),
    filename: "test.3mf",
    content_type: "application/x-3mf"
  )

  assert print_pricing.three_mf_file.attached?
end

test "should validate 3mf file size" do
  print_pricing = print_pricings(:one)
  # Test with 101MB file (over limit)
  # Assert validation fails
end

test "should validate 3mf file content type" do
  print_pricing = print_pricings(:one)
  file = file_fixture("sample.txt")

  print_pricing.three_mf_file.attach(
    io: File.open(file),
    filename: "test.txt",
    content_type: "text/plain"
  )

  assert_not print_pricing.valid?
  assert_includes print_pricing.errors[:three_mf_file], "invalid content type"
end

test "three_mf_file_attached_and_pending? returns true when file attached and status pending" do
  print_pricing = print_pricings(:one)
  print_pricing.three_mf_file.attach(io: StringIO.new("test"), filename: "test.3mf")
  print_pricing.three_mf_import_status = "pending"

  assert print_pricing.three_mf_file_attached_and_pending?
end

test "three_mf_file_attached_and_pending? returns false when processing" do
  print_pricing = print_pricings(:one)
  print_pricing.three_mf_file.attach(io: StringIO.new("test"), filename: "test.3mf")
  print_pricing.three_mf_import_status = "processing"

  assert_not print_pricing.three_mf_file_attached_and_pending?
end
```

**Run tests**:

```bash
bin/rails test test/models/print_pricing_test.rb
```

#### Step 18: Create System Tests

```bash
touch test/system/three_mf_import_test.rb
```

**Content**:

```ruby
require "application_system_test_case"

class ThreeMfImportTest < ApplicationSystemTestCase
  setup do
    @user = users(:john)
    sign_in @user
  end

  test "user can upload 3MF file and see pending status" do
    visit new_print_pricing_path

    fill_in I18n.t('print_pricing.job_name'), with: "3MF Import Test"

    # Select printer
    select printers(:ender_3).name, from: I18n.t('print_pricing.printer')

    # Upload file
    file_path = file_fixture("sample_fdm.3mf")
    attach_file "3MF File", file_path

    click_button I18n.t('actions.create')

    # Should see success message and pending status
    assert_text I18n.t('print_pricing.created')
    assert_text I18n.t('print_pricing.three_mf.status.pending')
  end

  test "shows completed status after processing" do
    print_pricing = @user.print_pricings.create!(
      job_name: "Test Job",
      printer: printers(:ender_3),
      units: 1
    )
    print_pricing.plates.create!(printing_time_hours: 0, printing_time_minutes: 0)

    file = file_fixture("sample_fdm.3mf")
    print_pricing.three_mf_file.attach(
      io: File.open(file),
      filename: "test.3mf",
      content_type: "application/x-3mf"
    )

    # Process job synchronously
    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(print_pricing.id)
    end

    visit edit_print_pricing_path(print_pricing)

    assert_text I18n.t('print_pricing.three_mf.status.completed')
  end

  test "shows error for invalid file" do
    visit new_print_pricing_path

    fill_in I18n.t('print_pricing.job_name'), with: "Invalid File Test"

    # Try to upload non-3MF file
    file_path = file_fixture("sample.txt")
    attach_file "3MF File", file_path

    # Client-side validation should prevent submission
    # Or server-side validation should show error
  end

  test "client-side validation prevents large files" do
    visit new_print_pricing_path

    # Attach oversized file
    # Stimulus controller should show alert
    # File input should be cleared
  end
end
```

**Run tests**:

```bash
bin/rails test:system test/system/three_mf_import_test.rb
```

#### Step 19: Run Full Test Suite

```bash
# Run all tests
bin/rails test

# Should see ~1,100+ tests passing
# 0 failures, 0 errors

# Run CI checks
bin/ci
```

---

### Day 5: Documentation and Polish

#### Step 20: Update CLAUDE.md

**Edit**: `CLAUDE.md`

Add to "Core Architecture" section:

```markdown
### 3MF File Import

- **ThreeMfParser Service**: Parses 3MF files (ZIP archives containing XML) from slicers
- **Process3mfFileJob**: Background job processing uploaded 3MF files
- **ActiveStorage Integration**: File upload and S3 storage for 3MF files
- **Automatic Data Extraction**: Print time, material weight/volume, material type
- **Supports FDM and Resin**: Auto-detects technology and extracts appropriate data
```

Add to "Key Files" section:

```markdown
- `app/services/three_mf_parser.rb` - 3MF file parsing service
- `app/jobs/process3mf_file_job.rb` - Background job for 3MF processing
- `app/views/print_pricings/_three_mf_status.html.erb` - Status display partial
- `app/javascript/controllers/file_upload_validator_controller.js` - Client-side validation
- `docs/3MF_IMPORT_FEATURE.md` - Feature documentation
- `docs/3MF_IMPORT_PRD.md` - Product requirements document
```

#### Step 21: Verify Documentation

**Check files exist**:
- [x] `docs/3MF_IMPORT_FEATURE.md` - Technical documentation
- [x] `docs/3MF_IMPORT_PRD.md` - Product requirements
- [x] `docs/3MF_IMPORT_IMPLEMENTATION_PLAN.md` - This file

**Verify documentation is up-to-date**:
- [ ] Architecture diagrams accurate
- [ ] API documentation complete
- [ ] User guide written
- [ ] Troubleshooting section complete

#### Step 22: Manual Testing Checklist

**Basic Upload Flow**:
- [ ] Upload FDM 3MF from PrusaSlicer
- [ ] Upload FDM 3MF from Cura
- [ ] Upload Resin 3MF from Chitubox
- [ ] Upload Resin 3MF from Lychee Slicer
- [ ] Verify extracted data is correct
- [ ] Verify material matching works
- [ ] Verify status updates (pending → processing → completed)

**Error Handling**:
- [ ] Upload non-3MF file (should reject)
- [ ] Upload 101MB file (should reject)
- [ ] Upload corrupted 3MF (should show error)
- [ ] Upload 3MF with no metadata (should handle gracefully)
- [ ] Upload 3MF with unknown material (should fallback)

**Edge Cases**:
- [ ] Upload 3MF when no materials exist (should log warning)
- [ ] Upload 3MF to existing PrintPricing (should update)
- [ ] Upload multiple 3MF files (should queue)
- [ ] Concurrent uploads from different users (should work)

**UI/UX**:
- [ ] Status display shows correct state
- [ ] Error messages are user-friendly
- [ ] Download button works
- [ ] File size displays correctly
- [ ] Responsive on mobile
- [ ] Works in all 7 languages

**Performance**:
- [ ] Small file (<1MB) processes in <2s
- [ ] Large file (50MB) processes in <10s
- [ ] Temp files cleaned up after processing
- [ ] No memory leaks after 10+ uploads

---

### Day 5: Commit and Deploy

#### Step 23: Commit Changes

```bash
# Add all new files
git add -A

# Verify changes
git status
git diff --staged

# Commit with descriptive message
git commit -m "Add 3MF file import feature

Implements automatic extraction of print time and material data from
3MF files exported by slicers (PrusaSlicer, Cura, Chitubox, etc.).

Features:
- ThreeMfParser service for parsing 3MF ZIP archives
- Process3mfFileJob for background processing via SolidQueue
- ActiveStorage integration for file upload to S3
- Auto-detection of FDM vs Resin technology
- Material matching with user's filament/resin library
- Status tracking (pending, processing, completed, failed)
- Client-side file validation (size, type)
- Comprehensive error handling and retry logic
- Full internationalization (7 languages)
- 100+ tests with 95%+ coverage

Technical Details:
- Uses rubyzip for ZIP archive handling
- Nokogiri for XML parsing
- ActiveStorage for file management
- SolidQueue for background jobs
- Stimulus for client-side validation

Closes #[issue-number] (if applicable)
Resolves requirements from docs/3MF_IMPORT_PRD.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

#### Step 24: Run Pre-Deployment Checks

```bash
# Run full test suite
bin/ci

# Should output:
# ✓ Brakeman security scan passed
# ✓ Rubocop style check passed
# ✓ Rails tests passed (1,100+ tests)
# ✓ JavaScript tests passed (20+ tests)

# Verify translations
bin/check-translations

# Check for any missing keys or hardcoded strings
```

#### Step 25: Push and Create PR

```bash
# Push branch
git push origin feature/3mf-import-feature

# Create pull request
gh pr create \
  --title "Add 3MF File Import Feature" \
  --body "$(cat << 'EOF'
## Overview

Implements automatic extraction of print time and material data from 3MF files uploaded from slicers.

## Changes

- **New Service**: `ThreeMfParser` - Parses 3MF ZIP archives and extracts metadata
- **New Job**: `Process3mfFileJob` - Background processing via SolidQueue
- **Model Update**: `PrintPricing` - Added 3MF file attachment and status tracking
- **UI Components**: File upload field, status display, client-side validation
- **Internationalization**: Full i18n support for all 7 languages

## Testing

- 100+ new tests added
- Full coverage of parser, job, and UI components
- Manual testing completed for all supported slicers

## Documentation

- `docs/3MF_IMPORT_FEATURE.md` - Technical documentation
- `docs/3MF_IMPORT_PRD.md` - Product requirements
- `docs/3MF_IMPORT_IMPLEMENTATION_PLAN.md` - Implementation guide
- `CLAUDE.md` updated with new architecture details

## Screenshots

[TODO: Add screenshots of UI]

## Related Issues

Closes #[issue-number]
Based on research from PR #42

## Checklist

- [x] All tests passing
- [x] Documentation complete
- [x] Translations synced
- [x] Security audit passed
- [x] Manual testing completed
- [ ] Screenshots added
- [ ] Ready for review
EOF
)"

# Or use web interface:
gh pr view --web
```

#### Step 26: Deploy to Production

**After PR approval and merge**:

```bash
# Switch to main branch
git checkout main
git pull origin main

# Verify latest changes
git log --oneline -5

# Run final checks
bin/ci

# Deploy via Kamal
kamal deploy

# Monitor deployment
kamal app logs -f

# Verify in production
curl -I https://calcumake.com/print_pricings/new
# Should return 200 OK
```

#### Step 27: Post-Deployment Verification

**Production Checks**:

```bash
# SSH into production server
kamal app exec -i sh

# Inside container, check Ruby gems
bundle list | grep rubyzip

# Check job queue
bin/rails runner "puts SolidQueue::Job.count"

# Exit container
exit

# Test file upload in production
# (Use browser or curl)
```

**Monitor Logs**:

```bash
# Watch application logs
kamal app logs -f

# Filter for 3MF-related logs
kamal app logs | grep "3mf\|ThreeMfParser\|Process3mfFileJob"

# Check SolidQueue dashboard
# Visit: https://calcumake.com/solid_queue (if enabled)
```

**Verify S3 Storage**:

```bash
# Check Hetzner S3 bucket for uploaded files
# (Use web console or AWS CLI)

aws s3 ls s3://your-bucket-name/three-mf-files/ \
  --endpoint-url=https://fsn1.your-objectstorage.com \
  --profile calcumake
```

**Test End-to-End**:

1. Log into production as test user
2. Navigate to Print Pricings → New
3. Upload a 3MF file
4. Verify status shows "pending"
5. Wait 30 seconds
6. Refresh page
7. Verify status shows "completed"
8. Verify extracted data is correct
9. Download 3MF file (verify download works)
10. Test error case (upload invalid file)

---

## Troubleshooting

### Common Issues

#### Issue: Job not processing

**Symptoms**: Status stays "pending" indefinitely

**Diagnosis**:
```bash
# Check SolidQueue is running
kamal app exec "ps aux | grep solid_queue"

# Check for errors in logs
kamal app logs | grep "Process3mfFileJob"

# Check job count
kamal app exec "bin/rails runner 'puts SolidQueue::Job.where(queue_name: :default).count'"
```

**Solution**:
- Restart SolidQueue: `kamal app restart`
- Check database connection
- Verify worker processes running

#### Issue: Parse errors

**Symptoms**: Status shows "failed" with error message

**Diagnosis**:
```bash
# Check error message in database
kamal app exec "bin/rails runner 'puts PrintPricing.where(three_mf_import_status: :failed).last&.three_mf_import_error'"

# Check for parser errors
kamal app logs | grep "ThreeMfParser::ParseError"
```

**Solution**:
- Verify 3MF file is valid (test with slicer)
- Check for unsupported slicer format
- Add new metadata field support if needed

#### Issue: Material matching fails

**Symptoms**: Warning in logs "No matching filament/resin found"

**Diagnosis**:
```bash
# Check user's materials
kamal app exec "bin/rails runner 'user = User.find(ID); puts user.filaments.pluck(:material_type)'"

# Check extracted material type
kamal app logs | grep "material_type"
```

**Solution**:
- User needs to create matching material first
- Improve fuzzy matching logic
- Add fallback material suggestion

#### Issue: S3 upload fails

**Symptoms**: File not uploaded, ActiveStorage error

**Diagnosis**:
```bash
# Check S3 credentials
kamal app exec "bin/rails credentials:show | grep s3"

# Test S3 connection
kamal app exec "bin/rails runner 'ActiveStorage::Blob.service.upload(...)'"
```

**Solution**:
- Verify S3 credentials in credentials file
- Check network connectivity
- Verify bucket permissions

---

## Post-Launch Tasks

### Week 1: Monitoring

- [ ] Monitor error rates (target: <5%)
- [ ] Monitor processing times (target: <5s avg)
- [ ] Monitor S3 storage usage
- [ ] Monitor user adoption (40% target)
- [ ] Collect user feedback
- [ ] Respond to support tickets

### Week 2: Analysis

- [ ] Review error logs for patterns
- [ ] Identify unsupported slicer formats
- [ ] Analyze most common material types
- [ ] Measure time savings vs manual entry
- [ ] Survey user satisfaction (target: 4.5+ stars)
- [ ] Plan improvements based on feedback

### Month 1: Iteration

- [ ] Add support for additional slicers (if needed)
- [ ] Improve material matching algorithm
- [ ] Add more error context for users
- [ ] Optimize parser performance
- [ ] Write blog post announcing feature
- [ ] Create video tutorial

### Quarter 1: Enhancements

- [ ] Implement real-time status updates (Turbo Streams)
- [ ] Add thumbnail extraction
- [ ] Support multi-plate detection
- [ ] Support multi-material prints
- [ ] Add preview mode
- [ ] Plan API support for slicer plugins

---

## Success Metrics

### Technical Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Parse success rate | 95%+ | `(completed / total_uploads) * 100` |
| Avg processing time | <5s | `avg(processing_end - processing_start)` |
| Error rate | <5% | `(failed / total_uploads) * 100` |
| S3 storage cost | <$50/mo | Hetzner S3 billing dashboard |
| Test coverage | 95%+ | `SimpleCov` output |

### Product Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| User adoption | 40%+ | `users_who_uploaded / active_users * 100` |
| Feature usage | 25%+ regular | Users with 3+ uploads in 30 days |
| Time savings | 70%+ reduction | Survey: "How much time saved?" |
| User satisfaction | 4.5+ stars | In-app rating prompt |
| Support tickets | <10/month | Support system dashboard |

### Business Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| User retention | +10% | 30-day retention rate |
| Premium upgrades | +5% | Conversion to paid plans |
| Pricing accuracy | +50% improvement | Error rate in quotes |
| NPS score | +15 points | User survey |

---

## Conclusion

This implementation plan provides a step-by-step guide to implementing the 3MF file import feature. Follow each step carefully, test thoroughly, and monitor closely after deployment.

**Key Success Factors**:
1. Comprehensive testing (100+ tests)
2. Clear error messages and user guidance
3. Performance optimization (<5s processing)
4. Strong security (validation, sandboxing)
5. Excellent documentation (user + developer)
6. Active monitoring and quick iteration

**Next Steps After Implementation**:
1. Launch announcement (blog post, email)
2. User education (tutorials, help docs)
3. Feedback collection (surveys, interviews)
4. Iteration based on data (Phase 2 features)

---

**Document Version**: 1.0
**Last Updated**: 2026-01-27
**Author**: Claude Code with Cody Baldwin
**Status**: Ready for Execution
