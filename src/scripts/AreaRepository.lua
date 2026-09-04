Leveling.AreaRepository = Leveling.AreaRepository or {}

local AreaRepository = Leveling.AreaRepository

-- Static package data. Preserve route strings, definition order, and descriptions.
local areas = {
    ["KoreSprings"] = {
        ["dirs"] = {
            "n","n","n","n","n","n","n","n","n","n","n",
            "n","n","n","s","s","s","e","e","e","e","e",
            "e","e","n","s","s","e","n","n","n","n","e",
            "e","e","e","s","e","s","s","s","s","w","s",
            "w","w","w","w","n","n","n","e","n","s","s",
            "e","n","n","s","e","e","n","s","w","w","w",
            "w","w","w","w","w","w","w","w","w","s","s",
            "s","s","s","s","s","s","s","s","s"
        },
        ["allowed_mobs"] =
        {
            {
                name = "retainer",
                description = "One of the lord's retainers is here keeping an eye on the lord's lands.",
            },
            {
                name = "joni",
                description = "Joni Shagrin, once Senior Bannerman of the Guards, is here with a blood stained bandage around his temple.",
            },
            {
                name = "soldier",
                description = "A grey haired experienced soldier stands here next to a saddled horse holding a long, steel-tipped lance.",
            },
            {
                name = "squadman",
                description = "A former squadman straightens his sword belt.",
            },
            {
                name = "lord",
                description = "A bluff faced, stocky man with thick gray hair sits at a writing table.",
            },
            {
                name = "horse",
                description = "A saddled horse looks prepared for a campaign.",
            }
        },
        ["description"] = "From just south of the entrance to Kore Springs",
    },
    ["TrollocCamp"] = {
        ["dirs"] = {
            "w","n","s","s","n","w","n","s","s","n","w",
            "n","s","s","n","w","n","s","w","n","s","s",
            "n","w","s","n","n","n","n","e","s","n","e",
            "s","n","e","s","n","e","s","n","e","s","n",
            "w","w","w","w","w","s","s","s","e","n","s",
            "e","s","s","e","w","s","e","w","w","n","s",
            "w","n","s","s","s","s","n","e","n","s","e",
            "n","s","e","w","s","e","w","w","e","s","w",
            "e","s","s","n","e","n","s","s","n","e","n",
            "s","s","n","e","s","s","s","w","n","s","w",
            "n","s","w","n","s","w","n","s","w","n","n",
            "e","w","s","s","e","e","e","e","e","n","n",
            "n","n","n","w","e","n","w","e","n","w","e",
            "n","w","e","n","w"
        },
        ["allowed_mobs"] =
        {
            {
                name = "troll",
                description = "A trolloc scout screams and attacks",
            },
            {
                name = "troll",
                description = "A trolloc warrior stands here with a look of blood lust in his eyes",
            },
            {
                name = "troll",
                description = "A trolloc soldier screams and attacks",
            },
            {
                name = "bloodlord",
                description = "A bloodlord stands here studying the ancient books of legend",
            },
            {
                name = "dreadlord",
                description = "A dreadlord stands here studying the books of knowledge",
            },
            {
                name = "darkhound",
                description = "A darkhound is standing here",
            },
            {
                name = "chief",
                description = "A trolloc chieftain stands here with a wicked toothy grin",
            }
        },
        ["description"] = "Start 1 east of the trolloc camp, in the blight.",
    },
    ["Drones"] = {
        ["dirs"] = {
            "down", "east", "east", "east", "north", "north", "north", "north",
            "west", "north", "east", "east", "south", "west", "south", "south",
            "south", "south", "west", "west", "west", "south", "south", "south",
            "east", "east", "east", "east", "south", "south", "east", "east", "east",
            "south", "south", "east", "north", "west", "north", "west", "west", "west",
            "south", "south", "south", "west", "west", "west", "west", "south", "north",
            "north", "north", "west", "south", "south", "south", "west", "north", "north",
            "north", "west", "south", "south", "south", "west", "north", "north", "north",
            "south", "east", "north", "north", "north", "north", "west", "west", "west",
            "west", "west", "west", "west", "west", "north", "north", "north", "west",
            "north", "south", "east", "east", "north", "south", "west", "south", "south", "south", "east",
            "east", "south", "south", "south", "south", "south", "south", "south", "south",
            "west", "west", "west", "west", "west", "north", "north", "north", "north",
            "north", "south", "south", "south", "south", "south", "south", "south", "south",
            "south", "south", "west", "north", "north", "north", "north", "north", "north",
            "north", "north", "north", "north", "west",  "south", "south", "south", "south",
            "south", "south", "south", "south", "south", "south", "east", "east", "north",
            "north", "north", "north", "north", "east", "east", "east", "east", "east",
            "north", "north", "north", "north", "north", "north", "north", "north", "east",
            "east", "east", "east", "east", "east", "east", "east", "east", "north", "north",
            "north", "up"
        },
        ["allowed_mobs"] = {
            {
                name = "drone",
                description = "a face-hugger parasite is here, fighting YOU!",
            },
            {
                name = "drone",
                description = "This alien drone hasn't yet reached full adulthood",
            },
            {
                name = "alien",
                description = "Long, spindly legs are slowly emerging from this open egg!",
            },
            {
                name = "drone",
                description = "An alien drone moves subtly along the darkended walls",
            },
            {
                name = "drone",
                description = "A vicious alien drone spaps its double-jaws",
            },
            {
                name = "drone",
                description = "An abnormally large alien drone looms over you",
            },
            {
                name = "drone",
                description = "An alien drone races across the ceiling.",
            },
            {
                name = "marine",
                description = "This marine opens fire on anything that moves!",
            }
        },
        ["description"] = "Start at the hole in the wall, where you go just 1 down for drones.",
    }
}

--- Returns a configured area, or nil for an unknown canonical name.
--- The returned definition is shared static data; callers must not mutate it.
function AreaRepository:get(areaName)
    return areas[areaName]
end

--- Returns the shared name-to-definition table for the existing pairs listing.
--- No sorting or session state is introduced here.
function AreaRepository:list()
    return areas
end
