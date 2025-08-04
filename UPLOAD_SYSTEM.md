# Upload System Documentation

This document explains how the file upload system works in the Makanan Segar application.

## Overview

The application supports two types of uploads:
1. **Product Images** - For vendor product listings
2. **Profile Images** - For vendor profile pictures

## Architecture

### Components

1. **Upload Module** (`lib/makanan_segar/uploads.ex`)
   - Handles file storage and validation
   - Generates unique filenames
   - Stores files in the `priv/static/uploads` directory

2. **LiveView Upload Integration**
   - Product Form (`lib/makanan_segar_web/live/vendor/product_live/form.ex`)
   - Profile Form (`lib/makanan_segar_web/live/vendor/profile_live.ex`)

3. **Context Layer Integration**
   - Products context handles product image uploads
   - Accounts context handles profile image uploads

## Upload Flow

### 1. Frontend (LiveView)
- Configure upload with `allow_upload/3`
- Provide drag-and-drop interface
- Show upload previews and progress
- Handle upload errors

### 2. File Processing
- Consume uploaded entries with `consume_uploaded_entry/3`
- Convert to `%Plug.Upload{}` struct
- Pass to context layer

### 3. Backend Storage
- Validate file type and size
- Generate unique filename using UUID
- Copy file to persistent storage
- Return public URL path

## Configuration

### Upload Constraints
- **File Types**: JPG, JPEG, PNG, WebP
- **Max File Size**: 5MB
- **Max Entries**: 1 file per upload

### Directory Structure
```
priv/static/uploads/
├── products/
│   ├── [uuid].jpg     # Product images
│   ├── [uuid].png
│   └── ...
├── [uuid].jpg         # Profile images
├── [uuid].png
└── ...
```

### Static File Serving
Files are served via Phoenix's static file handler at `/uploads/[filename]`.

## Product Image Upload

### Form Configuration
```elixir
allow_upload(:product_image,
  accept: ~w(.jpg .jpeg .png .webp),
  max_entries: 1,
  max_file_size: 5_000_000,
  auto_upload: false
)
```

### Processing in save_product/3
```elixir
uploaded_image =
  case socket.assigns.uploads.product_image.entries do
    [entry | _] ->
      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        %Plug.Upload{
          path: path,
          filename: entry.client_name,
          content_type: entry.client_type
        }
      end)
    [] ->
      nil
  end

# Products are stored with "products" subdirectory
Uploads.store(upload, "products")  # -> "/uploads/products/uuid.jpg"
```

## Profile Image Upload

### Form Configuration
```elixir
allow_upload(:profile_image,
  accept: ~w(.jpg .jpeg .png .webp),
  max_entries: 1,
  max_file_size: 5_000_000,
  auto_upload: false
)
```

### Processing in handle_event("save", ...)
```elixir
updated_user_params =
  case socket.assigns.uploads.profile_image.entries do
    [entry | _] ->
      upload_struct =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          %Plug.Upload{
            path: path,
            filename: entry.client_name,
            content_type: entry.client_type
          }
        end)
      Map.put(user_params, "profile_image_upload", upload_struct)
    [] ->
      user_params
  end

# Profile images are stored in main uploads directory
Uploads.store(upload)  # -> "/uploads/uuid.jpg"
```

## Validation

### File Type Validation
- Only allows: `.jpg`, `.jpeg`, `.png`, `.webp`
- Case-insensitive extension checking

### File Size Validation
- Maximum 5MB per file
- Validated on both frontend and backend

### Security Considerations
- Files are stored with UUID filenames to prevent conflicts
- Original filenames are not preserved in storage
- File content validation through extension checking

## Error Handling

### Upload Errors
- `:too_large` - File exceeds 5MB limit
- `:not_accepted` - Invalid file type
- `:too_many_files` - More than 1 file uploaded
- `:invalid_file_type` - Backend validation failure
- `:file_too_large` - Backend size validation failure

### Error Display
Errors are displayed in the UI with user-friendly messages:
```elixir
defp error_to_string(:too_large), do: "File too large (max 5MB)"
defp error_to_string(:not_accepted), do: "File type not accepted (only JPG, JPEG, PNG, WebP)"
```

### Database Schema

### Products Table
```sql
image: string  -- Stores public URL path like "/uploads/products/uuid.jpg"
```

### Users Table
```sql
profile_image: string  -- Stores public URL path like "/uploads/uuid.jpg"
```

## Testing

### Test Configuration
Upload directory is configured in `config/dev.exs`:
```elixir
uploads_dir = Path.join([__DIR__, "..", "priv", "static", "uploads"])
File.mkdir_p!(uploads_dir)
config :makanan_segar, :uploads_dir, uploads_dir
```

### Test Helpers
Tests use the standard `update_product/4` and `update_user_profile/2` functions with `nil` for upload parameters when not testing upload functionality.

## Troubleshooting

### Common Issues

1. **Uploads directory doesn't exist**
   - Ensure `priv/static/uploads` directory exists
   - For products: Ensure `priv/static/uploads/products` directory exists
   - Check directory permissions

2. **Files not appearing after upload**
   - Verify static file serving is configured
   - Check that `/uploads` is in `static_paths/0`
   - Verify correct subdirectory structure for products vs profiles

3. **Upload validation errors**
   - Check file type and size constraints
   - Verify MIME type detection

4. **Path inconsistency issues**
   - Product images should be stored in `/uploads/products/` subdirectory
   - Profile images are stored directly in `/uploads/` directory
   - Check database entries match the file system structure

### Debug Information
Upload operations are logged with debug information for troubleshooting.

### Fixed Issues
- **Path Consistency**: Product uploads now consistently use `/uploads/products/` subdirectory
- **Function Signatures**: Fixed `update_product/3` vs `update_product/4` signature issues
- **File Consumption**: Properly consume LiveView upload entries and convert to `Plug.Upload` structs
- **Error Handling**: Improved validation and error messages for upload failures

## Future Improvements

- Image resizing/optimization
- Multiple image uploads per product
- Cloud storage integration (S3, etc.)
- Image thumbnail generation
- Upload progress indicators
- Bulk upload functionality