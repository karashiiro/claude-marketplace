const fs = require("fs");
const path = require("path");

const stylePath = path.join(
  process.env.CLAUDE_PLUGIN_ROOT,
  "hooks-handlers",
  "style.txt",
);
const style = fs.readFileSync(stylePath, "utf8");

console.log(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: style,
    },
  }),
);
