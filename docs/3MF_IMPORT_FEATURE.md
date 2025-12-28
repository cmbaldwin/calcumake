# 3MF File Import Feature

## Overview

The 3MF Import feature allows users to upload 3MF files (3D Manufacturing Format) from slicer software like PrusaSlicer, Cura, or other compatible tools. The system automatically extracts print time, filament weight, and material information from these files to populate PrintPricing records.

## Architecture

### Components

1. **ActiveStorage Integration**
   - Files uploaded via `has_one_attached :three_mf_file` on PrintPricing model
   - Stored in AWS S3 via configured ActiveStorage service

2. **ThreeMfParser Service** (`app/services/three_mf_parser.rb`)
   - Pure Ruby implementation using `rubyzip` and `nokogiri`
   - Parses 3MF files (which are ZIP archives containing XML)
   - Extracts metadata from multiple slicer formats (PrusaSlicer, Cura, etc.)

3. **Process3mfFileJob** (`app/jobs/process3mf_file_job.rb`)
   - Background job using SolidQueue
   - Downloads and processes uploaded 3MF files
   - Updates PrintPricing and Plate records with extracted data
   - Handles errors and retries

4. **UI Components**
   - File upload field in print pricing form
   - Status indicators (pending, processing, completed, failed)
   - Stimulus controller for client-side validation

## Data Flow

```
User uploads 3MF file
   ↓
PrintPricing saves with attached file
   ↓
after_commit callback triggers Process3mfFileJob
   ↓
Job downloads file to temp location
   ↓
ThreeMfParser extracts metadata
   ↓
Job updates Plate records with:
   - printing_time_hours
   - printing_time_minutes
   - filament_weight (via PlateFilament)
   ↓
Status updated to 'completed' or 'failed'
```

## Supported Metadata

The parser attempts to extract the following from 3MF files:

### Print Settings
- **Print Time**: Extracted from various formats (seconds, HH:MM:SS, human readable)
- **Filament Weight**: Parsed from grams, kilograms, or raw numbers
- **Material Type**: PLA, ABS, PETG, TPU, etc.

### Slicer-Specific Fields

**PrusaSlicer**:
- `estimated_printing_time`
- `total_filament_used`
- `material_type`
- `layer_height`
- `nozzle_diameter`

**Cura**:
- `time`
- `material`
- `material_weight`

### Mesh Data
- Vertex count
- Triangle count
- Bounding box (width, depth, height)

## File Format

3MF files are ZIP archives containing:

```
3mf-file.3mf/
├── _rels/
│   └── .rels                  # Relationship definitions
├── 3D/
│   └── 3dmodel.model          # Main model file (XML)
├── Metadata/
│   └── model_metadata.xml     # Optional metadata
└── [other files]
```

The parser reads:
1. `3D/3dmodel.model` - Main model with mesh data and metadata
2. `_rels/.rels` - Relationship information
3. Metadata elements embedded in the model file

## Implementation Details

### Validation

The PrintPricing model validates:
- File must be attached with `.3mf` extension
- Content type must be one of:
  - `application/x-3mf`
  - `application/vnd.ms-package.3dmanufacturing-3dmodel+xml`
  - `application/zip`

### Error Handling

- Job retries up to 3 times on `ThreeMfParser::ParseError`
- Failed imports store error message in `three_mf_import_error` field
- Status tracked via `three_mf_import_status`:
  - `nil` or `"pending"` - Not yet processed
  - `"processing"` - Currently being processed
  - `"completed"` - Successfully imported
  - `"failed"` - Import failed with error

### Filament Matching

The job attempts to match extracted material types with user's existing filaments:
1. Case-insensitive LIKE match on material_type
2. Exact match on uppercase material_type
3. Fallback to first available filament
4. Logs warning if no match found

## Usage

### For Users

1. Create or edit a PrintPricing
2. In the "Import from 3MF File" section, click "Choose File"
3. Select a `.3mf` file from your slicer
4. Submit the form
5. File processes in background - status shown on edit page
6. Once completed, plate data is automatically populated

### For Developers

#### Adding New Slicer Support

To support additional slicer metadata formats, update `ThreeMfParser`:

```ruby
def extract_your_slicer_metadata(doc, namespaces)
  [
    "your_field_name",
    "another_field"
  ].each do |field|
    extract_metadata_field(doc, namespaces, field)
  end
end
```

Then call it from `extract_slicer_metadata`:

```ruby
def extract_slicer_metadata(zip_file)
  # ... existing code ...
  extract_your_slicer_metadata(doc, namespaces)
end
```

#### Custom Metadata Fields

The parser stores unknown metadata fields as-is:

```ruby
@metadata[name.to_sym] = value
```

These can be accessed from the parsed metadata hash.

## Database Schema

### Migration

```ruby
class AddThreeMfImportStatusToPrintPricings < ActiveRecord::Migration[8.1]
  def change
    add_column :print_pricings, :three_mf_import_status, :string
    add_column :print_pricings, :three_mf_import_error, :text
  end
end
```

### ActiveStorage Tables

Uses existing ActiveStorage tables:
- `active_storage_attachments`
- `active_storage_blobs`
- `active_storage_variant_records`

## Testing

### Manual Testing

1. Export a 3MF file from PrusaSlicer with known settings:
   - Print time: 2h 30m
   - Filament weight: 75.5g
   - Material: PLA

2. Upload to CalcuMake
3. Verify extracted values match expected values

### Sample 3MF Structure

```xml
<!-- 3D/3dmodel.model -->
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
  <metadata name="prusaslicer:print_time">9000</metadata>
  <metadata name="prusaslicer:filament_weight">75.5</metadata>
  <metadata name="prusaslicer:material_type">PLA</metadata>
  <resources>
    <object id="1" type="model">
      <mesh>
        <vertices>
          <vertex x="0" y="0" z="0"/>
          <!-- more vertices -->
        </vertices>
        <triangles>
          <triangle v1="0" v2="1" v3="2"/>
          <!-- more triangles -->
        </triangles>
      </mesh>
    </object>
  </resources>
</model>
```

## Limitations

1. **Single Plate Import**: Currently creates/updates only the first plate
2. **Filament Matching**: Requires existing filament records for material type
3. **Slicer Variations**: Metadata field names vary between slicers
4. **No Multi-Material**: Doesn't handle multi-material prints yet
5. **Background Processing**: User must refresh to see completed import

## Future Enhancements

1. **Real-time Updates**: Turbo Stream broadcasts for completion status
2. **Multi-Plate Support**: Parse multiple build plates from single file
3. **Multi-Material**: Extract multiple filament types and weights
4. **Slicer Detection**: Identify source slicer and adapt parsing
5. **Preview**: Show extracted data before saving
6. **Auto-Filament Creation**: Suggest creating new filament if no match
7. **Thumbnails**: Extract embedded preview images
8. **Advanced Metadata**: Parse support material, infill percentage, etc.

## Dependencies

- **rubyzip** (gem): ZIP archive handling
- **nokogiri** (gem): XML parsing
- **solid_queue** (gem): Background job processing
- **activestorage**: File attachment and storage

## References

- [3MF Specification](https://github.com/3MFConsortium/spec_core)
- [3MF Consortium](https://3mf.io/)
- [lib3mf Library](https://github.com/3MFConsortium/lib3mf)
- [ActiveStorage Guide](https://guides.rubyonrails.org/active_storage_overview.html)
- [SolidQueue Documentation](https://github.com/rails/solid_queue)

## Translation Keys

All user-facing text is internationalized under `print_pricing.three_mf.*`:

```yaml
en:
  print_pricing:
    three_mf:
      import_title: Import from 3MF File
      file_label: Upload 3MF File
      help_text: Upload a 3MF file from your slicer...
      status:
        pending: Pending
        processing: Processing...
        completed: Import Successful
        failed: Import Failed
```

## Security Considerations

1. **File Validation**: Only `.3mf` files accepted
2. **Size Limit**: Client-side validation for 100MB max
3. **Virus Scanning**: Consider adding antivirus scanning for production
4. **Sandboxing**: Parse in isolated background job
5. **User Scope**: Files scoped to authenticated user's records only

## Performance

- **File Size**: Most 3MF files are 1-50MB
- **Processing Time**: ~1-5 seconds for typical files
- **Storage**: Files stored in S3, not consuming application server disk
- **Concurrency**: Multiple imports can process simultaneously via SolidQueue

---

**Version**: 1.0
**Last Updated**: 2025-11-18
**Author**: Claude Code
