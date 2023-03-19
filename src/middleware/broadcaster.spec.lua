return function()
	local createProducer = require(script.Parent.Parent["create-producer"]).createProducer
	local combineProducers = require(script.Parent.Parent["combine-producers"]).combineProducers
	local applyMiddleware = require(script.Parent.Parent["apply-middleware"]).applyMiddleware
	local createBroadcaster = require(script.Parent["broadcaster"]).createBroadcaster

	local function copyProducerMap()
		return {
			a = createProducer({ count = 0 }, {
				incrementA = function(state, amount)
					return { count = state.count + amount }
				end,
			}),
			b = createProducer({ count = 0 }, {
				incrementB = function(state, amount)
					return { count = state.count + amount }
				end,
			}),
		}
	end

	describe("createBroadcaster", function()
		it("should return a broadcaster", function()
			local broadcaster = createBroadcaster({
				producers = copyProducerMap(),
				broadcast = function() end,
			})

			expect(broadcaster).to.be.a("table")
			expect(broadcaster.middleware).to.be.a("function")
			expect(broadcaster.playerRequestedState).to.be.a("function")
		end)
	end)

	describe("Broadcaster", function()
		it("should have a middleware function", function()
			local producerMap = copyProducerMap()

			local broadcaster = createBroadcaster({
				producers = producerMap,
				broadcast = function() end,
			})

			expect(function()
				combineProducers(producerMap):enhance(applyMiddleware(broadcaster.middleware))
			end).never.to.throw()
		end)

		it("should call broadcast when a dispatcher is called", function()
			local producerMap = copyProducerMap()

			local playersToBroadcastTo
			local actionsToBroadcast

			local broadcaster = createBroadcaster({
				producers = producerMap,
				broadcast = function(players, actions)
					playersToBroadcastTo = players
					actionsToBroadcast = actions
				end,
			})

			local producer = combineProducers(producerMap):enhance(applyMiddleware(broadcaster.middleware))

			producer.incrementA(1)

			task.defer(function()
				expect(playersToBroadcastTo).to.be.a("table")
				expect(actionsToBroadcast).to.be.a("table")
				expect(actionsToBroadcast[1]).to.be.a("table")
				expect(actionsToBroadcast[1].type).to.equal("incrementA")
				expect(actionsToBroadcast[1].arguments).to.be.a("table")
				expect(actionsToBroadcast[1].arguments[1]).to.equal(1)
			end)
		end)
	end)
end