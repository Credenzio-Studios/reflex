local TS = require(game:GetService("ReplicatedStorage").include.RuntimeLib)
local Reflex = TS.import(script, game:GetService("ReplicatedStorage"), "reflex")
local Rodux =
	TS.import(script, game:GetService("ReplicatedStorage"), "include", "node_modules", "@rbxts", "rodux", "src")

--[[
	Benchmarker

	Run type: Time
	Run time: 1 second

	Reflex.createProducer:   80 microseconds
	Reflex.combineProducers: 120 microseconds
	Rodux.createReducer:     130 microseconds
	Rodux.combineReducers:   170 microseconds

	Reflex's combineProducers is 30% faster than Rodux's combineReducers in this
	benchmark, but there is still a 40% overhead from Reflex's createProducer.
]]

return {
	ParameterGenerator = function()
		local result = {
			producer = Reflex.combineProducers({
				a = Reflex.createProducer({ count = 0 }, {
					incrementA = function(state, amount)
						return { count = state.count + amount }
					end,
				}),
				b = Reflex.createProducer({ count = 0 }, {
					incrementB = function(state, amount)
						return { count = state.count + amount }
					end,
				}),
			}),

			producerUncombined = Reflex.createProducer({ a = { count = 0 }, b = { count = 0 } }, {
				incrementA = function(state, amount)
					return { a = { count = state.a.count + amount }, b = state.b }
				end,
				incrementB = function(state, amount)
					return { b = { count = state.b.count + amount }, a = state.a }
				end,
			}),

			store = Rodux.Store.new(Rodux.combineReducers({
				a = Rodux.createReducer({ count = 0 }, {
					incrementA = function(state, action)
						return { count = state.count + action.amount }
					end,
				}),
				b = Rodux.createReducer({ count = 0 }, {
					incrementB = function(state, action)
						return { count = state.count + action.amount }
					end,
				}),
			})),

			storeUncombined = Rodux.Store.new(Rodux.createReducer({ a = { count = 0 }, b = { count = 0 } }, {
				incrementA = function(state, action)
					return { a = { count = state.a.count + action.amount }, b = state.b }
				end,
				incrementB = function(state, action)
					return { b = { count = state.b.count + action.amount }, a = state.a }
				end,
			})),
		}

		task.defer(function()
			result.store:destruct()
			result.storeUncombined:destruct()
		end)

		return result
	end,

	Functions = {
		["Reflex.combineProducers"] = function(profiler, parameter)
			for _ = 1, 100 do
				parameter.producer.incrementA(1)
				parameter.producer.incrementB(1)
			end
		end,

		["Reflex.createProducer"] = function(profiler, parameter)
			for _ = 1, 100 do
				parameter.producerUncombined.incrementA(1)
				parameter.producerUncombined.incrementB(1)
			end
		end,

		["Rodux.combineReducers"] = function(profiler, parameter)
			for _ = 1, 100 do
				parameter.store:dispatch({ type = "incrementA", amount = 1 })
				parameter.store:dispatch({ type = "incrementB", amount = 1 })
			end
		end,

		["Rodux.createReducer"] = function(profiler, parameter)
			for _ = 1, 100 do
				parameter.storeUncombined:dispatch({ type = "incrementA", amount = 1 })
				parameter.storeUncombined:dispatch({ type = "incrementB", amount = 1 })
			end
		end,
	},
}
