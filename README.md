# omarchy-library

Every public [Omarchy](https://omarchy.org/) cookbook in one place: **[INDEX.md](INDEX.md)** to browse, [index.json](index.json) for agents.

A cookbook is a GitHub repo of recipes, each fixing one problem with stock Omarchy, in the [omarchy-kitchen](https://github.com/duff/omarchy-kitchen) format.

## Get your cookbook listed

Add the topic `omarchy-cookbook` to your cookbook's repo:

```bash
gh repo edit <you>/omarchy-cookbook --add-topic omarchy-cookbook
```

The index is rebuilt every day. A cookbook has to pass `kitchen check`, the same check its own GitHub Action runs. Ones that don't are listed under "Not passing the check" until they're fixed.

To leave, remove the topic. Your cookbook drops out at the next build.

## What the index shows

- **Cookbooks**: everyone's, with how many recipes each has.
- **Most applied**: recipes found in more than one cookbook. Each copy records where it came from, so the library can count how far a recipe has traveled.
- **Ideas for Omarchy**: recipes their authors marked as a better default, or as a workaround for an Omarchy bug, most applied first. If you work on Omarchy, start here.

## Safety

Listing isn't an endorsement. Everything in the index is copied from other people's repos, cleaned up, and shown as data. Your agent still gives every recipe a safety review before offering it, and applies nothing without your yes.

To report a cookbook with harmful recipes, open an issue. Removed cookbooks are listed in [blocklist.json](blocklist.json) with the reason.
