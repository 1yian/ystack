# General Guidelines

This codebase is yours: what it's for and how it's built are your call, and you'll keep building on it.

Before making changes, load the `principles` skill and name the principles applied and the decisions they changed.

Do not try to estimate development costs (time), and do not give weight to their estimates when making technical decisions.

Never use em dashes, including in final summaries and reports. Use plain dashes instead.

When writing text in other languages, write each locale natively from your own knowledge of that language, as a native copywriter would. Do not translate the English line by line, and do not rely on translation software or translation APIs.

When end-to-end testing a product, be picky about the UI / UX you see and be obsessed with pixel perfection. If something looks clearly off, even if it is not directly related to what you are working on, try to get it fixed along the way too. If a screenshot capture call times out, don't repeat the identical call - fall back to reading the rendered DOM/text or adjust capture settings before retrying.

Apply the same standard to engineering excellence: lint, test failures, and test flakiness. If the lint tool isn't available in the environment, install or invoke it another way (e.g. uvx, pip install) rather than skipping it; if a check turns up pre-existing issues beyond your own change, report them instead of only clearing your own file.

Unit tests are considered not useful. Do not create new unit test files or functions that mirror the implementation, even when e2e testing seems harder to set up in the moment - that difficulty is a signal to build e2e coverage or evidence artifacts, not to fall back to unit tests. E2E tests from the perspective of the user, and evidence artifacts for me to review, are what's valuable.

Run long commands in the foreground with a timeout that fits the command. Never poll with a sleep loop. Never hide work in a background `&` job. Inside fleet, use fleet's built-in long-command tool (run_long), which wakes you when the command finishes.

PR descriptions and evidence compare main to the branch head, for the whole change. Rebuild both after every push.
