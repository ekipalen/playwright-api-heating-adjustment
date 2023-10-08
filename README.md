# Adjust heating temperature based on the current electricity price.

This robot:

- Uses [Robot Framework](https://robocorp.com/docs/languages-and-frameworks/robot-framework/basics) syntax.
- Gets the current electricity price (Finnish) via API.
- Gets the current date and time via API to get the current time using a specific timezone. 
- Sets the heating temperature if needed. 
