-- Places in the world (Core\World.lua): a map spot's continent and yards, and the player's. The
-- simulated world has Elwynn Forest (1429) with its middle at x 400, y -9000 on continent 0, and
-- map 1430 right east of it.

describe("Places in the world", function()
    it("places a map spot in the world, x along the map's x axis and y along its y axis", function()
        local Kennel = NewClient():login().Kennel
        assert.are.same({ 0, 400, -9000 }, { Kennel.InWorld(1429, 0.5, 0.5) })
        local _, x, y = Kennel.InWorld(1429, 0.6, 0.5)
        assert.is_true(math.abs(x - (400 - 347)) < 0.001, "east is a lower x")
        assert.are.equal(-9000, y)
        _, x, y = Kennel.InWorld(1429, 0.5, 0.6)
        assert.are.equal(400, x)
        assert.is_true(math.abs(y - (-9000 - 231.4)) < 0.001, "south is a lower y")
        assert.is_nil((Kennel.InWorld(9999, 0.5, 0.5)), "a map the client cannot place")
    end)

    it("places the player from UnitPosition, else from its map position, else nowhere", function()
        local client = NewClient():login()
        local Kennel = client.Kennel
        client.worldPos = { -8000, 100, 1 }
        assert.are.same({ 1, 100, -8000 }, { Kennel.PlayerInWorld() })
        client.worldPos = nil
        assert.are.same({ 0, 400, -9000 }, { Kennel.PlayerInWorld() }, "Elwynn's middle")
        client.mapWorld = {}
        assert.is_nil((Kennel.PlayerInWorld()), "a map the client cannot place")
        client.mapPos = nil
        assert.is_nil((Kennel.PlayerInWorld()), "no map position")
    end)
end)
