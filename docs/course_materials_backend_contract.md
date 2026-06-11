# Course Materials Backend Contract

Backend reference: `C:\uni\exe201\edunest\EduNest_Backend`

The backend already has a flat `DataAccessLayer.Entities.Material` entity scoped to `Availability`. To support the mobile feature cleanly, extend it into section-based course materials.

## Data Model

Add:

```csharp
public sealed class MaterialSection
{
    public int MaterialSectionId { get; set; }
    public int AvailabilityId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public Availability Availability { get; set; } = null!;
    public ICollection<Material> Materials { get; set; } = new List<Material>();
}
```

Update `Material`:

```csharp
public int? MaterialSectionId { get; set; }
public string? FileName { get; set; }
public string? ContentType { get; set; }
public long? FileSize { get; set; }
public string MaterialType { get; set; } = "File"; // File / Pdf / Image / Video / Link
public DateTime? UpdatedAt { get; set; }
public MaterialSection? Section { get; set; }
```

Keep `AvailabilityId` on `Material` for fast authorization checks and backward compatibility.

## DTOs

```csharp
public sealed class MaterialSectionResponse
{
    public int SectionId { get; set; }
    public int AvailabilityId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<MaterialResponse> Items { get; set; } = new();
}

public sealed class MaterialResponse
{
    public int MaterialId { get; set; }
    public int? SectionId { get; set; }
    public int AvailabilityId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? FileUrl { get; set; }
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public long? FileSize { get; set; }
    public string MaterialType { get; set; } = "File";
    public DateTime CreatedAt { get; set; }
}
```

Requests:

```csharp
public sealed class UpsertMaterialSectionRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public sealed class UpsertMaterialRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? FileUrl { get; set; }
}
```

For file upload endpoints, accept `IFormFile? file` plus `Title`, `Description`, and optional `FileUrl`.

## Endpoints

Controller route: `[Route("api/material")]`

Learner and tutor:

```text
GET /api/material/availability/{availabilityId}
```

Return `List<MaterialSectionResponse>`. Authorize tutors who own the availability and parents/students with a paid/enrolled booking for that availability.

Tutor only:

```text
POST   /api/material/availability/{availabilityId}/sections
PUT    /api/material/sections/{sectionId}
DELETE /api/material/sections/{sectionId}

POST   /api/material/sections/{sectionId}/items
PUT    /api/material/items/{materialId}
DELETE /api/material/items/{materialId}
```

Use `[Authorize(Roles = "Tutor")]` on mutation endpoints.

## Authorization Rules

- Tutor can manage only materials where `Availability.Tutor.UserId == CurrentUserId()`.
- Parent/student can view only when they have a non-deleted paid/active booking for the availability.
- Deleting a section should delete its material items or reject if the section is not empty. The mobile UI assumes cascade delete.

## Storage

The existing app has `ICloudinaryService`; reuse it for uploaded files if it supports raw/PDF/video uploads, or add a storage abstraction that returns a public `FileUrl`. Store external video links directly in `FileUrl` with `MaterialType = "Link"`.
