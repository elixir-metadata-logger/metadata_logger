# Changelog

## [Unreleased]

## 0.3.0 - 2020-07-17

### Fixed

- Handle Elixir logger metadata: `domain`, `callers`, `ancestors`

### Changed

- Produce JSON when formating failed

## 0.2.1 - 2020-01-28

### Fixed

- Handle erlang logger metadata: `gid`, `mfa`, `report_cb`

## 0.2.0 - 2019-11-14

### Added

- `MetadataLogger.log_to_map/4`

### Changed

- Renamed from `metadata_logger_json_formatter` to `metadata_logger`.
- `MetadataLogger.format/4` now returns IO data.

## 0.1.0 - 2018-08-08

[Unreleased]: https://github.com/elixir-metadata-logger/metadata_logger/compare/v0.2.1...HEAD
