# The library's JSON rules: cleaning someone else's text, building the
# index, and rendering INDEX.md. Load with: jq -L lib 'include "library"; ...'

# Someone else's text, made safe for a Markdown table and for agents: one
# line, no markup characters, no hidden characters, and not too long.
def clean($limit):
  (. // "") | tostring
  | explode
  | map(
      if . < 32 or . == 127 then 32
      elif (. >= 8203 and . <= 8207) or (. >= 8234 and . <= 8238)
        or (. >= 8288 and . <= 8292) or (. >= 8294 and . <= 8297) or . == 65279 then empty
      else . end)
  | implode
  | gsub("[|<>`\\[\\]\\\\]"; "")
  | gsub(" +"; " ")
  | sub("^ "; "") | sub(" $"; "")
  | if length > $limit then .[0:$limit - 3] + "..." else . end;
def clean: clean(160);

def username: type == "string" and test("^[A-Za-z0-9-]{1,39}$");

# One recipe's index entry, from {data, folder}.
def recipe_entry($repo; $commit):
  .folder as $folder
  | .data
  | {
      id,
      url: "https://github.com/\($repo)/blob/\($commit)/recipes/\($folder)/RECIPE.md",
      title: (.title | clean),
      summary: (.summary | clean),
      version,
      applies_to: (.applies_to | clean),
      requires: [.requires[] | map_values(if type == "string" then clean(60) else . end)],
      tested_on: (.tested_on | map_values(clean(20))),
      root, network,
      installs: [.installs[] | clean(60)],
      runs: [.runs[] | clean(60)],
      agent_config,
      upstream,
      upstream_link: (if (.upstream_link // "" | startswith("https://github.com/")) then .upstream_link else null end),
      obsolete_since,
      history: [.history[] | {who, did, date, parent} | with_entries(select(.value != null))]
    }
  | with_entries(select(.value != null));

# The whole index from a list of cookbook entries: the cookbooks, plus every
# recipe id across them with the cookbooks holding a copy and the recipes
# adapted from it.
def index($built; $checked_with):
  . as $cookbooks
  | (reduce ($cookbooks[] | . as $c | .recipes[] | {c: $c, r: .}) as $x ({};
      .[$x.r.id] |= (
        (. // {title: $x.r.title, created_by: $x.r.history[0].who, upstream: null,
               cookbooks: [], adapted_into: [], url: null})
        | .cookbooks += [$x.c.repo]
        | .upstream = (.upstream // $x.r.upstream)
        | if $x.c.owner == ($x.r.id | split("/")[0]) or .url == null
          then .url = $x.r.url | .title = $x.r.title else . end
      ))) as $grouped
  | (reduce ($cookbooks[] | .recipes[] | . as $r | .history[] | select(.parent != null)
             | {parent, id: $r.id}) as $a ($grouped;
      if .[$a.parent] then .[$a.parent].adapted_into |= (. + [$a.id] | unique) else . end)) as $recipes
  | {
      built: $built,
      checked_with: $checked_with,
      cookbooks: ($cookbooks | sort_by(.repo | ascii_downcase)),
      recipes: ($recipes | map_values(.cookbooks |= unique) | to_entries | sort_by(.key) | from_entries)
    };

def plural($n; $word): if $n == 1 then $word else "\($word)s" end;
def person: if username then "[@\(.)](https://github.com/\(.))" else "" end;
def most_applied_first: sort_by([-(.value.cookbooks | length), (.value.title | ascii_downcase), .key]);

def render:
  . as $i
  | [$i.cookbooks[] | select(.passes_check)] as $passing
  | [$i.cookbooks[] | select(.passes_check | not)] as $failing
  | ($i.recipes | length) as $count
  | ([$i.recipes | to_entries[] | select(.value.cookbooks | length > 1)] | most_applied_first | .[0:50]) as $shared
  | ([$i.recipes | to_entries[] | select(.value.upstream != null)] | most_applied_first) as $ideas
  | [
      "# Omarchy cookbook library",
      "",
      "Built on \($i.built) from every public GitHub repo with the topic `omarchy-cookbook`: \($passing | length) \(plural($passing | length; "cookbook")) and \($count) \(plural($count; "recipe")). See [README.md](README.md) to add yours, or [index.json](index.json) for agents.",
      "",
      "## Cookbooks",
      "",
      (if ($passing | length) == 0 then "None yet."
       else "| Cookbook | About | Recipes | Updated |", "|---|---|---|---|",
         ($passing[] | "| [\(.repo)](\(.url)) | \(.description) | \(.recipes | length) | \((.pushed_at // "")[0:10]) |")
       end),
      "",
      "## Most applied",
      "",
      "Recipes found in more than one cookbook.",
      "",
      (if ($shared | length) == 0 then "None yet."
       else "| Recipe | Created by | Cookbooks | Adapted |", "|---|---|---|---|",
         ($shared[] | .value | "| [\(.title)](\(.url)) | \(.created_by | person) | \(.cookbooks | length) | \(.adapted_into | length) |")
       end),
      "",
      "## Ideas for Omarchy",
      "",
      "Recipes their authors marked as a better default or a bug workaround, most applied first.",
      "",
      (if ($ideas | length) == 0 then "None yet."
       else "| Recipe | Kind | Cookbooks |", "|---|---|---|",
         ($ideas[] | .value
          | "| [\(.title)](\(.url)) | \(if .upstream == "bug" then "bug workaround" else "better default" end) | \(.cookbooks | length) |")
       end),
      (if ($failing | length) == 0 then empty
       else "", "## Not passing the check", "",
         "These have the topic but don't pass `kitchen check`, so their recipes aren't listed.", "",
         ($failing[] | "- [\(.repo)](\(.url)): \(.problems) \(plural(.problems; "problem"))")
       end)
    ]
  | join("\n") + "\n";
