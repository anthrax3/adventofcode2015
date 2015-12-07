#!/usr/bin/awk -f
{
  s += gsub(/\(/, "")
  s -= gsub(/\)/, "")
}
END { print s }
