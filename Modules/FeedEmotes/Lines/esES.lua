local _, ns = ...

-- Spanish emote lines, for both esES and esMX. The feed sentence and the first lines of most lists
-- come from Feed-O-Matic; food-type lines, the families from Bear onwards and the extra family
-- lines were written for FeedPetEmotes.

---@type Addon
local Addon = ns
local M = Addon:GetModule("FeedEmotes") --[[@as BeastkeeperFeedEmotes]]
local F = M.Family

M.Lines.esES = {
    feed = "alimenta a %s con %s. ",
    feedNoFood = "alimenta a %s. ",

    pronouns = {
        ["él"] = { male = "él", female = "ella" },
        -- No {his}: "su" is the same for a male and a female pet.
        -- Only the noun changes: "¡Qué {chico}!" fits, "¡Buen {chico}!" does not.
        chico = { male = "chico", female = "chica" },
    },

    emotes = {
        any = {
            "¡Ñam!",
            "Mmm, está rico.",
            "¡Ehh! ¡Cuidado con mis dedos!",
            "Om nom nom nom...",
            "¡Un mordisco y listo!",
            "Mmm, delicioso.",
            "¡Gurps!",
            "¡Así se come, {chico}!",
            "¡Eh, que son mis dedos, no su postre!",
        },
        male = { "¡Buen chico!" },
        female = { "¡Buena chica!" },
        food = {
            zesty = { "¡Mmm, sabrosa!" },
            mystery = {
                "Sabe a pollo.",
                "¡Sabe a zancudo!",
                "Sabe a gnomo viejo.",
                "Sabe a... ¿araña?",
            },
            chili = { "¡Guau, picante!" },
            watermelon = { "¡Vaya bocaza!" },
        },
        foodType = {
            bread = {
                "¡Carbohidratos! ¡Gloriosos carbohidratos!",
                "Recién salido del horno.",
                "¿Quién necesita carne si hay pan?",
            },
            meat = { "Nada como un buen trozo de carne.", "¡Aprobado por carnívoros!", "Poco hecho, como te gusta." },
            fish = { "¡Recién llegado del puerto!", "Aquí huele a pescado...", "Sin salsa tártara, gracias." },
            cheese = { "¡Queso para la fiera!", "Un poco apestoso, justo como le gusta a {él}.", "¡Di «queso»!" },
            fruit = {
                "¡Una manzana al día, y el veterinario en la lejanía!",
                "Cargando vitaminas.",
                "¡Elección saludable!",
            },
            fungus = { "Qué viaje...", "¿Seguro que son de los comestibles?", "Setas, qué rico." },
        },
        family = {
            [F.BOAR] = { "¡Buen cerdito!", "Oinc oinc, ñam ñam.", "¡Buscador de trufas de servicio!" },
            [F.CAT] = { "¡Buen gatito!", "¡Miau-ravilloso!", "¿Quién es el gatito más bonito?" },
            [F.HYENA] = { "¡Buen perro!", "¡Deja de reírte y come!", "¿Quién se ríe ahora?" },
            [F.WOLF] = { "¡Buen perro!", "¿Quién es un buen lobo?", "¡Auuuuu!" },
            [F.SPIDER] = {
                "¿De verdad tienes que envolverlo antes de comértelo?",
                "Ocho patas, un solo apetito.",
                "¡Nada de telarañas en mis dedos!",
            },
            [F.RAPTOR] = { "¡Abajo, dino!", "Chica lista...", "¡Tranquilo, asesino!" },
            [F.DEVILSAUR] = {
                "¡Abajo, dino!",
                "¡Grandes bocados para un gran dino!",
                "¡No me comas a mí después!",
            },
            [F.CROCOLISK] = { "¡Caramba, qué rápido lo ha atrapado!", "¡Ñac, ñac!", "¡Cuidado con los dientes!" },
            [F.CORE_HOUND] = {
                "¡Qué chiquitín más bueno!",
                "Ay, lo están compartiendo.",
                "¡Eh, no os peleéis por eso!",
            },
            [F.CHIMAERA] = {
                "¡Eh, no os peleéis por eso!",
                "Dos cabezas, el doble de apetito.",
                "Compartid bien, las dos.",
            },
            [F.BEAR] = {
                "¿Quién es un osito peludo? ¡Tú!",
                "¡Guarda algo para hibernar!",
                "¡Qué hambre de oso!",
            },
            [F.BIRD_OF_PREY] = {
                "¿Quién es un buen pájaro?",
                "¡Tragado de un bocado!",
                "Vista aguda, estómago vacío. ¡Ya no!",
            },
            [F.TALLSTRIDER] = { "¡Buen pajarito!", "¡Todo cuello y nada de modales!", "¡Pic, pic, pic!" },
            [F.CARRION_BIRD] = {
                "¡Fresco, para variar!",
                "¿No está lo bastante muerto para ti?",
                "¡Un carroñero con estilo!",
            },
            [F.WIND_SERPENT] = {
                "¡Zas! ¡Desaparecido!",
                "¡No electrocutes la mano que te da de comer!",
                "¡Sorbido de un trago!",
            },
            -- Written for Beastkeeper: Fox is new in WoW: Forever.
            [F.FOX] = {
                "¡Zorro astuto!",
                "Ni una miga para las gallinas.",
                "Un bailecito alrededor del plato, y al ataque.",
                "Robado limpiamente.",
                "El más listo de la mesa.",
            },
            [F.BAT] = { "¡Buen murcielaguito!", "Al menos no es sangre.", "Come bien, pequeño volador nocturno." },
            [F.CRAB] = { "¡Chas, chas!", "¿También come de lado?", "¡Pinza, pinza, y fuera!" },
            [F.GORILLA] = {
                "¿Quién es un buen gorila?",
                "¿No hay plátanos? Bueno, esto servirá.",
                "¡Uh uh ah ah!",
            },
            [F.SCORPID] = { "¡Cuidado con el aguijón!", "¿Buen... bicho?", "Pinzar y picar, ¡qué combo!" },
            [F.TURTLE] = { "Despacito y con buena letra.", "Tómate tu tiempo. En serio.", "Sin prisa pero sin pausa." },
        },
    },
}
M.Lines.esMX = M.Lines.esES
