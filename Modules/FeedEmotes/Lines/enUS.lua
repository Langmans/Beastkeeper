local _, ns = ...

-- English emote lines, also used by a client language that has none of its own. From
-- Feed-O-Matic unless marked otherwise.

---@type Kennel
local Kennel = ns
local M = Kennel:GetModule("FeedEmotes") --[[@as KennelFeedEmotes]]
local F = M.Family

-- Head nouns that take "some": food you do not count (meat, bread, cheese
-- names, dishes from a pot). Plurals ("Deep Fried Plantains") take it as
-- well. Taken from the item names in tests/data/forever-food.lua (Wowhead's
-- Forever food and meat lists) and tests/data/forever-scan.lua (what the
-- client lets a pet eat beyond those); tests/feedemotes_food_spec.lua checks
-- every one.
local UNCOUNTED = {
    -- meat
    meat = true,
    jerky = true,
    boar = true,
    brisket = true,
    venison = true,
    flesh = true,
    ichor = true,
    raptor = true,
    hachee = true,
    bruscitti = true,
    rouladen = true,
    mandu = true,
    -- bread
    bread = true,
    cornbread = true,
    butter = true,
    flour = true,
    rye = true,
    pumpernickel = true,
    sourdough = true,
    -- cheese
    cheddar = true,
    skycheddar = true,
    brie = true,
    bleu = true,
    swiss = true,
    sharp = true,
    mild = true,
    -- from a pot or a bowl
    stew = true,
    soup = true,
    chowder = true,
    gumbo = true,
    goulash = true,
    broth = true,
    bisque = true,
    chili = true,
    linguine = true,
    salad = true,
    kimchi = true,
    jam = true,
    -- the rest
    mold = true,
    sludge = true,
    fruit = true,
    pulp = true,
    taffy = true,
    cream = true,
    feed = true,
    seaweed = true,
    corn = true,
    breath = true,
    -- Drinks: no pet drinks them, but Wowhead lists them with the food.
    water = true,
    tea = true,
    juice = true,
    milk = true,
    nog = true,
    nectar = true,
    dew = true,
    smoothie = true,
    punch = true,
    brew = true,
    beer = true,
    ale = true,
    lager = true,
    stout = true,
    malt = true,
    wine = true,
    grog = true,
    rum = true,
    brandy = true,
    applejack = true,
    moonshine = true,
    firewater = true,
    reserve = true,
    gold = true,
}

---"a", "an" or "some" for a food's plain name. The head noun decides: the
---word before "of" or "with" ("Haunch of Meat" -> Haunch, "Bread with
---Butter" -> Bread), else the last word. Uncounted food and plurals take
---"some"; otherwise the first letter picks "a" or "an".
---@param name string
---@return string
local function article(name)
    local head = (name:match("^(.-) of ") or name:match("^(.-) with ") or name):match("(%S+)$") or name
    head = head:lower()
    if UNCOUNTED[head] or (head:match("s$") and not head:match("[su]s$")) then return "some" end
    return name:match("^[AEIOUaeiou]") and "an" or "a"
end

M.Lines.enUS = {
    -- The /emote text in front of the random line; one of the openings below takes its place now
    -- and then. food is an item link or a plain name; the article follows the name.
    ---@param pet string
    ---@param food string
    ---@return string
    feed = function(pet, food)
        return string.format("feeds %s %s %s. ", pet, article(food:match("|h%[(.-)%]|h") or food), food)
    end,
    -- Without a known food.
    feedNoFood = "feeds %s. ",
    -- {a} in the openings and whole sentences.
    article = article,

    -- Placeholders for emote lines: {he} becomes he or she from the pet's sex,
    -- {boy} boy or girl ("Good {boy}!"), each the pet's name when the sex is
    -- unknown; {his} his or her, "Fluffy's" when it is unknown (`unknown`, see
    -- M.FillPlaceholders).
    pronouns = {
        he = { male = "he", female = "she" },
        boy = { male = "boy", female = "girl" },
        his = { male = "his", female = "her", unknown = "%s's" },
    },

    emotes = {
        any = {
            "Yum!",
            "Mmm, good stuff.",
            "Hey! Watch the fingers!",
            "Om nom nom nom...",
            "One gulp and it's gone!",
            "Mmm, delicious.",
            "Burp!",
            "Yay, bag space!",
            "Who's a good {boy}?",
            "That's my {boy}!",
            "Straight down the hatch and into {his} belly.",
            "Hey, those are my fingers, not {his} dessert!",
            "Clean plate club!",
            "Chew, don't inhale!",
            "No, you can't have seconds. ...Fine.",
            "Don't tell the other hunters I spoil you.",
            "And that's why my bags are always empty.",
            "That one comes out of your loot share.",
            "Another satisfied customer.",
            "Loyalty: bought and paid for.",
        },
        -- Openings and whole sentences were written for this addon. An opening
        -- takes FEED's place: {a} {food} is the article and the item link.
        -- Each ends with the pet having its food, so any line can follow.
        openings = {
            "tosses {pet} {a} {food}.",
            "drops {a} {food} into {pet}'s bowl.",
            "hands {pet} {a} {food}.",
            "lets {pet} snatch {a} {food} right out of the bag.",
            "slips {pet} {a} {food} when nobody is looking.",
            "throws {a} {food} in the air, and {pet} catches it.",
            "rewards {pet} with {a} {food}.",
            "feeds {pet} {a} {food} by hand.",
            "puts down {a} {food}, and {pet} pounces on it.",
            "offers {pet} {a} {food} with a little bow.",
            "serves {pet} {a} {food}, fresh from the bag.",
            "bribes {pet} with {a} {food}.",
            "treats {pet} to {a} {food}.",
            "waves {a} {food} under {pet}'s nose, just long enough for a grab.",
            "gives {pet} {a} {food} as a well-earned snack.",
        },
        -- A whole emote on its own, no FEED and no line after it.
        whole = {
            "and {pet} have a staring contest over {a} {food}. {pet} wins.",
            "tries to share {a} {food} with {pet}. {pet} does not believe in sharing.",
            "turns around for one second. The {food} is gone, and {pet} looks very innocent.",
            "holds out {a} {food}. {pet} takes it, and most of the glove.",
            "asks {pet} to sit for {a} {food}. {pet} skips straight to the eating part.",
            "drops {a} {food}. It never touches the ground: {pet} is faster.",
            "gives {pet} {a} {food} and gets a look that says: that's it?",
            "hides {a} {food} in a pocket. {pet} finds it in two seconds.",
            "counts to three before giving {pet} {a} {food}. {pet} counts faster.",
            "cuts {a} {food} into neat little bites. {pet} swallows it whole.",
            "watches {pet} wolf down {a} {food} before {he} even sniffs it.",
        },
        -- Whole emotes for one family, mixed in with the ones above.
        wholeFamily = {
            [F.WOLF] = {
                "throws {a} {food} like a stick. {pet} fetches it straight into {his} belly.",
                "says 'sit' and holds up {a} {food}. {pet} sits, howls once, and the {food} is gone.",
            },
            [F.CAT] = {
                "puts {a} {food} on the table. {pet} knocks it off, then eats it off the floor.",
                "offers {pet} {a} {food}. {pet} sniffs it, walks away, and eats it once nobody is looking.",
            },
            [F.SPIDER] = {
                "drops {a} {food} near {pet}. A moment later it is neatly wrapped in silk.",
                "tosses {a} {food} into the web. {pet} wraps it up for later. Later is now.",
            },
            [F.BEAR] = {
                "opens the bag for {a} {food}. {pet} helps by sticking {his} whole head in.",
                "hands {pet} {a} {food}. {pet} looks for the honey first, then eats it anyway.",
            },
            [F.BOAR] = {
                "hides {a} {food} under a pile of leaves. {pet} snouts it out in two snorts.",
                "sets down {a} {food}. {pet} charges it at full speed. The {food} loses.",
            },
            [F.CROCOLISK] = {
                "holds {a} {food} over the water on a stick. Snap. The {food} is gone, and so is half the stick.",
                "tosses {a} {food} to {pet}, who swallows it and lies very still, waiting for more.",
            },
            [F.CARRION_BIRD] = {
                "leaves {a} {food} out in the sun for a while, just the way {pet} likes it.",
                "puts down {a} {food}. {pet} circles it three times before landing on it.",
            },
            [F.CRAB] = {
                "holds out {a} {food}. {pet} takes it with one claw and pinches the hand with the other.",
                "drops {a} {food} on the sand. {pet} scuttles over sideways and snips it to bits.",
            },
            [F.GORILLA] = {
                "hands {pet} {a} {food}. {pet} beats {his} chest, then eats it very politely.",
                "peels {a} {food} for {pet}. {pet} eats the peel too.",
            },
            [F.RAPTOR] = {
                "holds out {a} {food}. {pet} takes it, then checks whether the hand is next.",
                "tosses {a} {food} to {pet}, who snaps it out of the air. Clever {boy}.",
            },
            [F.TALLSTRIDER] = {
                "holds {a} {food} up high. {pet} does not even need to stretch.",
                "puts {a} {food} on the ground. {pet} pecks at it until it is gone, staring at nothing.",
            },
            [F.SCORPID] = {
                "puts down {a} {food}. {pet} stings it first, just to be sure.",
                "offers {pet} {a} {food} from a very safe distance.",
            },
            [F.TURTLE] = {
                "puts {a} {food} in front of {pet}. {pet} gets there eventually.",
                "waits while {pet} eats {a} {food}. And waits. And waits.",
            },
            [F.BAT] = {
                "throws {a} {food} into the air. {pet} catches it upside down.",
                "feeds {pet} {a} {food} at midnight, the only proper mealtime for a bat.",
            },
            [F.HYENA] = {
                "drops {a} {food}. {pet} laughs at it, then eats it.",
                "hands {pet} {a} {food}. {pet} giggles all the way through it.",
            },
            [F.BIRD_OF_PREY] = {
                "holds up a gloved hand with {a} {food}. {pet} swoops down and takes it in one pass.",
                "tosses {a} {food} high. {pet} is a feathered blur, and the {food} is gone.",
            },
            [F.WIND_SERPENT] = {
                "throws {a} {food} into the wind. {pet} catches it with a crackle of lightning.",
                "holds out {a} {food}. {pet} coils around the arm and takes it gently.",
            },
            -- Written for Kennel: Fox is new in WoW: Forever.
            [F.FOX] = {
                "holds out {a} {food}. {pet} does a little trickster's dance, then snatches it.",
                "turns around for a moment. {pet} has already buried the {food} for later, and is digging it up again.",
            },
        },
        male = { "Good boy!", "Atta boy!", "No more Mister Grumpy!" },
        female = { "Good girl!", "Atta girl!", "No more Miss Grumpy!" },
        food = {
            zesty = { "Mmm, zesty!" },
            mystery = {
                "Tastes like chicken.",
                "Tastes like tallstrider!",
                "Tastes like well-aged gnome.",
                "Tastes like... spider?",
            },
            chili = { "Yow, spicy!" },
            watermelon = { "What a big mouth!" },
            cherryPie = { "Tastes so good, makes a grown man cry." },
            warpBurger = { "Now how about some Nether Ray Fries?" },
            crunchy = { "Crunchy!" },
            minnow = { "Can has bigger fish?" },
        },
        -- Per food type (see M.FoodTypes). Only "Trippy..." is Feed-O-Matic's.
        foodType = {
            bread = { "Carbs! Glorious carbs!", "Fresh from the oven.", "Who needs meat when there's bread?" },
            meat = {
                "Nothing beats a good chunk of meat.",
                "Carnivore approved!",
                "Medium rare, just how you like it.",
            },
            fish = { "Fresh from the docks!", "Something smells fishy...", "Hold the tartar sauce." },
            cheese = { "Say cheese!", "Cheese for the beast!", "A little smelly, just how {he} likes it." },
            fruit = { "An apple a day keeps the vet away!", "Getting those vitamins in.", "Healthy choice!" },
            fungus = { "Trippy...", "Are you sure those are the edible ones?", "Fun guy, eating fungi." },
        },
        -- Feed-O-Matic had one line for most of the first ten families (three
        -- for Core Hound) and none for Bear onwards; the rest was written for
        -- this addon.
        family = {
            [F.BOAR] = {
                "Good piggy!",
                "Oink oink, nom nom.",
                "Truffle hunter on duty!",
                "That's going straight to {his} hips.",
                "Snort snort!",
                "Who needs a trough when you have me?",
                "Charge! ...at the snack, apparently.",
                "Bacon? Never heard of it.",
                "Mud bath after dinner, as usual.",
                "Tusks first, manners never.",
            },
            [F.CAT] = {
                "Nice kitty!",
                "Purr-fect!",
                "Who's a pretty kitty?",
                "Don't knock it off the table this time.",
                "Purring at full volume.",
                "Now ignore me like a proper cat.",
                "Cats don't have owners. They have staff.",
                "Nine lives, ten snacks.",
                "Comes when called? Only at dinner.",
                "Meow-velous!",
            },
            [F.HYENA] = {
                "Good dog!",
                "Stop laughing and eat!",
                "Who's laughing now?",
                "Hee hee hee... crunch.",
                "What's so funny about lunch?",
                "Laughing all the way to the bowl.",
                "Scavenger turned gourmet.",
                "Even the leftovers are giggling.",
                "No joke, that was fast.",
                "Giggles and gobbles.",
            },
            [F.WOLF] = {
                "Good dog!",
                "Who's a good wolf?",
                "Awoooo!",
                "Wolfed it down, naturally.",
                "Pack leader eats first. That's me, by the way.",
                "Howl if you want more!",
                "No sheep were harmed. Probably.",
                "The big bad wolf gets a snack.",
                "Fetch is after dinner.",
                "Lone wolf, full belly.",
            },
            [F.SPIDER] = {
                "Do you really have to wrap it up before eating it?",
                "Eight legs, one appetite.",
                "Don't get web on my fingers!",
                "Eight eyes, all on my bag.",
                "Silk-wrapped for freshness.",
                "Please don't save the rest on the ceiling.",
                "Itsy bitsy, hungry as anything.",
                "I'm not screaming, you're screaming.",
                "Web-to-table dining.",
                "Who's a good... arachnid?",
            },
            [F.RAPTOR] = {
                "Down, dino!",
                "Clever girl...",
                "Easy, killer!",
                "Still faster than me, even while eating.",
                "That's the sound of a happy predator.",
                "Rawr means thank you, right?",
                "Don't look at me like I'm dessert.",
                "Pack hunter, solo eater.",
                "Life finds a way. To the snack.",
                "Don't eat the quest giver, please.",
            },
            [F.DEVILSAUR] = {
                "Down, dino!",
                "Big bites for a big dino!",
                "Don't eat me next!",
                "That's a toothpick for you, isn't it?",
                "The ground shook. Lunch is served.",
                "Tiny arms, huge appetite.",
                "Un'Goro's finest, fed by hand.",
                "Please don't stomp the vendor.",
                "One bite. One whole stack.",
                "Mind the hunter, big one.",
            },
            [F.CROCOLISK] = {
                "Crikey, {he} snapped that up fast!",
                "Snap snap!",
                "Mind the teeth!",
                "See you later, alligator!",
                "A death roll for a ration? Bit much.",
                "Are those crocodile tears of joy?",
                "Lurking pays off.",
                "Now back in the swamp you go.",
                "Smile! ...no, close it again.",
                "Chomp!",
            },
            [F.CORE_HOUND] = {
                "What a good little puppy!",
                "Aww, they're sharing.",
                "Hey, don't fight over it!",
                "Two heads, one bowl, zero patience.",
                "Hot food? Everything's hot to you.",
                "Don't breathe fire on the bag, please.",
                "Molten Core's goodest pup.",
                "Left head ate it. Right head is sulking.",
                "Is it still warm, or is that you?",
                "Lava-proof appetite.",
            },
            [F.CHIMAERA] = {
                "Hey, don't fight over it!",
                "Two heads, twice the appetite.",
                "Share nicely, both of you.",
                "Left head: yum. Right head: also yum.",
                "One body, two opinions.",
                "Who gets the last bite? Fight later.",
                "Double the chewing, double the drool.",
                "Two heads are better than one at dinner.",
                "Don't spit lightning at the food.",
                "Winterspring's finest, twice over.",
            },
            [F.BEAR] = {
                "Who's a big fuzzy bear? You are!",
                "Save some for hibernation!",
                "Bear-ly a snack!",
                "Straight into {his} winter fat.",
                "Bear hug for the hunter?",
                "Honey next time, promise.",
                "Don't hibernate on me now.",
                "Grrrr... crunch.",
                "Unbearably cute.",
                "Fuzzy, hungry, perfect.",
            },
            [F.BIRD_OF_PREY] = {
                "Who's a good bird?",
                "Swallowed whole!",
                "Keen eyes, empty belly. Not anymore!",
                "Talons off the bag!",
                "Owl be right back with more.",
                "Hoo's hungry? Hoo indeed.",
                "Swoop, grab, gone.",
                "Eyes like a hawk, manners like a pigeon.",
                "Don't drop it from a height this time.",
                "Feathered and fed.",
            },
            [F.TALLSTRIDER] = {
                "Good birdie!",
                "All neck and no manners!",
                "Peck peck peck!",
                "Watch it travel all the way down.",
                "Kick back and enjoy.",
                "Mulgore's finest strider.",
                "Don't peck the hunter.",
                "Long neck, short attention span.",
                "Legs for days, appetite for weeks.",
                "Strut to the bowl!",
            },
            [F.CARRION_BIRD] = {
                "Fresh, for a change!",
                "Not dead enough for you?",
                "A vulture with standards!",
                "No need to circle, it's right here.",
                "Patience pays off.",
                "Freshly not-dead.",
                "Waiting for me to drop? Not today.",
                "Picky eater, for a vulture.",
                "Dinner without the waiting.",
                "Scrap, scrap, gulp.",
            },
            [F.WIND_SERPENT] = {
                "Zap! Gone!",
                "Don't shock the hand that feeds you!",
                "Slurped right up!",
                "Feeding a sky noodle.",
                "Static cling on the snack.",
                "Coiled up and happy.",
                "Shocking appetite!",
                "Lightning fast.",
                "Don't wrap around me after dinner.",
                "Hiss and sparkle.",
            },
            -- Written for Kennel: Fox is new in WoW: Forever.
            [F.FOX] = {
                "Sly fox!",
                "What does the fox say? Nom.",
                "Quick and brown, and now quite full.",
                "Not a crumb left for the hens.",
                "The cleverest one at the table.",
                "A swish of the tail says thanks.",
                "Stolen fair and square.",
                "Foxy and fed.",
                "A little dance around the bowl, then the pounce.",
                "Outfoxed by lunch? Never.",
            },
            [F.BAT] = {
                "Good little screecher!",
                "At least it's not blood.",
                "Eat up, little night flyer.",
                "Upside down is no way to eat.",
                "Echolocated: snack.",
                "Please don't screech at me.",
                "Night flyer, day snacker.",
                "Batty for food.",
                "Hang in there, more's coming.",
                "Squeak!",
            },
            [F.CRAB] = {
                "Snip snap!",
                "Does {he} eat sideways too?",
                "Pinch, pinch, gone!",
                "Feeling crabby? Not anymore.",
                "Shell out the snacks!",
                "Claws are not cutlery.",
                "Pinch me, I'm feeding a crab.",
                "Bubble bubble, munch munch.",
                "Scuttle to the bowl!",
                "Snappy service.",
            },
            [F.GORILLA] = {
                "Who's a good ape?",
                "No bananas? Fine, this will do.",
                "Ook ook!",
                "Chest-thumpingly good!",
                "Monkey business at dinner.",
                "Ape-solutely delicious.",
                "Don't throw it at me.",
                "King of the jungle? Close enough.",
                "Knuckle-walking to the bowl.",
                "Stranglethorn's finest table manners. So, none.",
            },
            [F.SCORPID] = {
                "Watch that stinger!",
                "Good... thing?",
                "Pinch and sting, what a combo!",
                "Tail up means happy, right?",
                "Sting-free feeding, please.",
                "Desert dining at its finest.",
                "Pincers, stinger, appetite.",
                "Don't sting the vendor.",
                "Crunchy outside, angry inside.",
                "Click click, nom.",
            },
            [F.TURTLE] = {
                "Slow and steady eats the snack.",
                "Take your time. Really.",
                "Shell yeah!",
                "This may take a while.",
                "Back in your shell, dinner's done.",
                "Hard shell, soft spot for snacks.",
                "Turtle-y awesome.",
                "Was that a bite or a nap?",
                "Fast food? Not here.",
                "Eats slow, eats everything.",
            },
        },
    },
}
