local _, ns = ...

-- French emote lines. The feed sentence and the first lines of most lists come from Feed-O-Matic;
-- food-type lines, the families from Bear onwards and the extra family lines were written for
-- FeedPetEmotes.

---@type Kennel
local Kennel = ns
local M = Kennel:GetModule("FeedEmotes") --[[@as KennelFeedEmotes]]
local F = M.Family

M.Lines.frFR = {
    feed = "donne à %s à manger un(e) %s. ",
    feedNoFood = "nourrit %s. ",

    pronouns = {
        Il = { male = "Il", female = "Elle" },
        -- No {his}: son/sa follows the thing owned, not the pet's sex.
        -- Only the noun changes: "Quel {garçon} !" would give "Quel fille".
        ["garçon"] = { male = "garçon", female = "fille" },
    },

    emotes = {
        any = {
            "Miam!",
            "Mmm, bonne bouffe.",
            "Hey! attention à mes doigts!",
            "Hum gloup gloup gloup gloup...",
            "Encore une bouchée et ca ira!",
            "Mmm, délicieux.",
            "Burp!",
            "Oui, un peu plus de place dans le sac!",
            "Chaque {garçon} sage mérite sa récompense !",
            "Hé, ce sont mes doigts, pas son dessert !",
        },
        male = { "Bon garçon!", "Attrape garçon!", "Pas plus monsieur le goinfre!" },
        female = { "Bonne fille!", "Attrape ma fille!", "Pas plus madame la goinfre!" },
        food = {
            zesty = { "Mmm, du crabe!" },
            mystery = {
                "Ca a un gout de poulet.",
                "Ca a un gout bouillie pour bébé!",
                "Ca a un gout de vieux gnome!",
                "Ca a un gout d'... araignée?",
            },
            chili = { "La vache, c'est épicé!" },
            watermelon = { "Quelle grande bouche!" },
            cherryPie = { "C'est si bon, ca en ferait hurler un muet." },
            crunchy = { "Crrrrrr!" },
            minnow = { "On dirait de la friture, T'as pas un plus gros poisson?" },
        },
        foodType = {
            bread = {
                "Des glucides ! De glorieux glucides !",
                "Tout chaud sorti du four.",
                "Qui a besoin de viande quand il y a du pain ?",
            },
            meat = {
                "Rien ne vaut un bon morceau de viande.",
                "Approuvé par les carnivores !",
                "Saignant, comme tu l'aimes.",
            },
            fish = { "Tout droit du port !", "Ça sent le poisson par ici...", "Sans sauce tartare, merci." },
            cheese = { "Ah, le fromage !", "Du fromage pour la bête !", "Un peu fort, juste comme il faut." },
            fruit = { "Une pomme par jour éloigne le vétérinaire !", "Plein de vitamines.", "Un choix sain !" },
            fungus = {
                "Ça va le faire planer...",
                "Tu es sûr qu'ils sont comestibles ?",
                "Des champignons, quel délice.",
            },
        },
        family = {
            [F.BOAR] = { "Bon cochon!", "Groin groin, miam miam.", "Chercheur de truffes en service !" },
            [F.CAT] = { "Bon minou!", "Ronron-parfait !", "C'est qui le joli minou ?" },
            [F.HYENA] = { "Bon chien!", "Arrête de rire et mange !", "Qui rit maintenant ?" },
            [F.WOLF] = { "Bon chien!", "C'est qui le bon loup ?", "Aouuuuh !" },
            [F.SPIDER] = {
                "Tu veux vraiment le recouvrir de bave avant de manger ça ?",
                "Huit pattes, un seul appétit.",
                "Pas de toile sur mes doigts !",
            },
            [F.RAPTOR] = { "Baisse toi, dino!", "Petite maligne...", "Doucement, le tueur !" },
            [F.DEVILSAUR] = { "Baisse toi, dino!", "Grosses bouchées pour un gros dino !", "Ne me mange pas après !" },
            [F.CROCOLISK] = { "Mange pas si vite satané croco!", "Clac clac !", "Attention aux dents !" },
            [F.CORE_HOUND] = {
                "C'est une bonne petite bête ça !",
                "Ho, faut savoir partager.",
                "Hey, combats pas sans ça!",
            },
            [F.CHIMAERA] = {
                "Hey, combats pas sans ça!",
                "Deux têtes, deux fois plus d'appétit.",
                "Partagez gentiment, toutes les deux.",
            },
            [F.BEAR] = {
                "C'est qui le gros nounours ? C'est toi !",
                "Garde-en pour l'hibernation !",
                "Une faim d'ours !",
            },
            [F.BIRD_OF_PREY] = {
                "C'est qui le bon oiseau ?",
                "Avalé tout rond !",
                "L'œil vif, le ventre vide. Plus maintenant !",
            },
            [F.TALLSTRIDER] = { "Gentil zoiseau !", "Que du cou et pas de manières !", "Pic, pic, pic !" },
            [F.CARRION_BIRD] = {
                "Du frais, pour une fois !",
                "Pas assez faisandé pour toi ?",
                "Un charognard aux goûts de luxe !",
            },
            [F.WIND_SERPENT] = {
                "Zap ! Disparu !",
                "On n'électrocute pas la main qui nourrit !",
                "Aspiré d'un coup !",
            },
            -- Written for Kennel: Fox is new in WoW: Forever.
            [F.FOX] = {
                "Rusé comme un renard !",
                "Pas une miette pour les poules.",
                "Un petit pas de danse autour de la gamelle, puis hop !",
                "Volé dans les règles de l'art.",
                "Le plus malin de la tablée.",
            },
            [F.BAT] = {
                "Gentille petite chauve-souris !",
                "Au moins, ce n'est pas du sang.",
                "Mange bien, petite créature de la nuit.",
            },
            [F.CRAB] = { "Clic, clac !", "{Il} mange aussi de travers ?", "Pince, pince, disparu !" },
            [F.GORILLA] = { "C'est qui le bon gorille ?", "Pas de bananes ? Bon, ça ira.", "Ouh ouh ah ah !" },
            [F.SCORPID] = { "Attention au dard !", "Gentille... bestiole ?", "Pincer et piquer, quel combo !" },
            [F.TURTLE] = {
                "Rien ne sert de courir...",
                "Prends ton temps. Vraiment.",
                "Bien à l'abri sous sa carapace !",
            },
        },
    },
}
