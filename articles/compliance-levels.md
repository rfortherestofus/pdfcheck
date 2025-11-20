# Compliance levels

Different profiles exist because **not all archival or accessibility
needs are the same**. PDF standards evolve, and each profile targets a
specific use case, level of strictness, or generation of the standard.
veraPDF mirrors these distinctions so it can validate documents
accurately against the exact rule set they claim to conform to.

## Why there are different profiles

1.  **Different versions of the PDF/A standard** PDF/A-1, -2, -3, and -4
    were introduced at different times. Each version adds or removes
    features (e.g., attachments, layers, engineering data, new PDF 2.0
    rules). A single profile wouldn’t be able to reflect all these
    variations.

2.  **Different strictness levels** Some workflows need full
    accessibility and semantic structure (A-level). Others only need the
    document to display correctly in the future (B-level). Some need
    reliable text extraction without full tagging (U-level).

3.  **Different intended uses** Archiving, accessibility, engineering
    content, file containers, or content reuse all require different
    rules. Profiles let software validate exactly the scenario a
    document was created for.

4.  **Separate standards beyond PDF/A** PDF/UA (accessibility) and WTPDF
    (web-friendly PDF standards) define their own requirements, so they
    get their own profiles.

## What the profiles represent

### PDF/A (archival profiles)

Used for long-term preservation. The “parts” reflect generations of the
standard:

- **PDF/A-1**: earliest, most restrictive.
- **PDF/A-2**: adds modern features (transparency, JPEG2000, layers,
  etc.).
- **PDF/A-3**: allows attaching non-PDF files.
- **PDF/A-4**: aligns with PDF 2.0 and simplifies levels.

Each part may include levels like:

- **A (Accessible)** — full tagging and structure.
- **B (Basic)** — visual preservation only.
- **U (Unicode)** — ensures extractable text.

So the profiles (1a, 1b, 2a, 2b, 2u…) are veraPDF’s way to validate the
exact combination of part + level.

### PDF/UA (accessibility profiles)

Focused entirely on ensuring documents are usable with assistive
technologies.

- **ua1**: first accessibility standard.
- **ua2**: updated for PDF 2.0.

These profiles check only accessibility requirements, not archival ones.

### WTPDF (web-technology PDF)

A newer specification aimed at structured, reusable, and accessible
content for digital use.

- **wt1r**: emphasizes clean content reuse.
- **wt1a**: accessibility-focused for web/pdf hybrid workflows.

## In short

- **Parts** represent *versions* of the standard.
- **Levels** represent *strictness and purpose*.
- **UA and WTPDF** exist for accessibility and modern web compatibility.
- veraPDF provides a profile for each combination so validation matches
  the document’s intended claim.
