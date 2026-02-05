# Accessibility report

Generates an HTML report on accessibility for a given PDF.

## Usage

``` r
accessibility_report(
  file,
  profile = "ua1",
  output_file = tempfile(fileext = ".html"),
  open = TRUE
)
```

## Arguments

- file:

  PDF file to check.

- profile:

  The validation profile to use. Default to `"ua1"`.

- output_file:

  Path for the HTML report. If `NULL`, creates a temp file.

- open:

  Whether to automatically open the report in browser. Default `TRUE`.

## Value

Path to the generated HTML report (invisibly)
