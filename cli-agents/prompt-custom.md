# Environment Notes

- When the user decides to record a work-environment issue, MUST read the `AGENT_ENV_NOTES_FILE` environment variable.
  If it is unset or its value is not in a standard file path format, MUST first ask the user.
  After obtaining a valid path, MUST read the file's existing content and
  record the case there according to environment conventions. If the file cannot be read, MUST ask the user to confirm how to proceed before writing.
- When the user decides to record project experience from such a case, MUST follow the current project's recording conventions. If none exist,
  MUST suggest an approach and obtain the user's decision before recording.
