/// Current date and time in the device's local time zone. Use this instead of
/// calling `DateTime.now()` directly so there is a single entry point.
DateTime nowLocal() => DateTime.now();

/// Converts [value] to the device's local time zone. Timestamps read from the
/// database come back as UTC and must go through this before being shown or
/// compared by calendar day.
DateTime asLocal(DateTime value) => value.toLocal();
