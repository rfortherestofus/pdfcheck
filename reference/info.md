# Retrieve specific accessibility info

Utility functions to retrieve specific informations about PDF
accessibility.

## Usage

``` r
get_total_failed_checks(x)

get_total_failed_rules(x)

get_verapdf_version(x)
```

## Arguments

- x:

  Output from
  [`verapdf()`](https://rfortherestofus.github.io/checkpdf/reference/verapdf.md)

## Note

It is important to understand the difference between rules and checks. A
rule that has been failed may be "Missing alternative text on images",
and each rule may have several checks that have been failed. For
example, if the rule "Missing alt text on images" occurs 10 times in a
given PDF, that gives us 10 failed checks for that rule.

## Examples

``` r
pdf_file <- system.file("pdf", "not-compliant-1.pdf", package = "checkpdf")

verapdf(pdf_file) |>
  get_total_failed_checks()
#> [1] 195

verapdf(pdf_file) |>
  get_total_failed_rules()
#> [1] 11

verapdf(pdf_file) |>
  get_verapdf_version()
#> [1] "1.28.2"
```
