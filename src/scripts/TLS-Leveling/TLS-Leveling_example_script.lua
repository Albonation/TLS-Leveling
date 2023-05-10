-- define TLS-Leveling_example_script() for use as an event handler
function TLS-Leveling_example_script(event, ...)
  echo("Received event " .. event .. " with arguments:\n")
  display(...)
end
