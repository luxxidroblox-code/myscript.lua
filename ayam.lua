local a = { cache = {} }
do
	do
		local function __modImpl()
			return {}
		end
		function a.a()
			local b = a.cache.a
			if not b then
				b = { c = __modImpl() }
				a.cache.a = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.a()

			local b = getfenv()

			local function readPath(c)
				local d = b
				for e in string.gmatch(c, "[^.]+") do
					if type(d) ~= "table" then
						return nil
					end
					d = d[e]
				end
				return d
			end

			local function resolveFunction(c, d)
				local e = readPath(c)
				if type(e) == "function" then
					return e
				end
				if d then
					for f, g in d do
						e = readPath(g)
						if type(e) == "function" then
							return e
						end
					end
				end
				return function()
					error(
						"sunc: executor API '"
							.. c
							.. "' is unavailable; use an executor implementing this API",
						2
					)
				end
			end

			local c = readPath("Drawing.Fonts")
			local d = if type(c) == "table" then c else nil

			local e = {
				DrawingImmediate = {
					Circle = resolveFunction("DrawingImmediate.Circle"),
					FilledCircle = resolveFunction("DrawingImmediate.FilledCircle"),
					FilledQuad = resolveFunction("DrawingImmediate.FilledQuad"),
					FilledRectangle = resolveFunction("DrawingImmediate.FilledRectangle"),
					FilledTriangle = resolveFunction("DrawingImmediate.FilledTriangle"),
					GetPaint = resolveFunction("DrawingImmediate.GetPaint"),
					Line = resolveFunction("DrawingImmediate.Line"),
					OutlinedText = resolveFunction("DrawingImmediate.OutlinedText"),
					Quad = resolveFunction("DrawingImmediate.Quad"),
					Rectangle = resolveFunction("DrawingImmediate.Rectangle"),
					Text = resolveFunction("DrawingImmediate.Text"),
					Triangle = resolveFunction("DrawingImmediate.Triangle"),
				},
				PsmSignal = {
					new = resolveFunction("PsmSignal.new", { "Signal.new" }),
				},
				Regex = {
					Escape = resolveFunction("Regex.Escape"),
					new = resolveFunction("Regex.new"),
				},
				cansignalreplicate = resolveFunction("cansignalreplicate"),
				create_comm_channel = resolveFunction("create_comm_channel"),
				dumpbytecode = resolveFunction("dumpbytecode"),
				get_comm_channel = resolveFunction("get_comm_channel"),
				getactors = resolveFunction("getactors", { "get_actors" }),
				getactorthreads = resolveFunction("getactorthreads", { "get_actor_threads" }),
				getbspval = resolveFunction("getbspval"),
				getconnection = resolveFunction("getconnection"),
				getdeletedactors = resolveFunction("getdeletedactors", { "get_deleted_actors" }),
				getfflagtype = resolveFunction("getfflagtype", { "getfastflagtype" }),
				getobjects = resolveFunction("getobjects"),
				getpcd = resolveFunction("getpcd", { "getpcdprop" }),
				getproximitypromptduration = resolveFunction("getproximitypromptduration"),
				getrendersteppedlist = resolveFunction("getrendersteppedlist"),
				getsignalarguments = resolveFunction("getsignalarguments"),
				getsignalargumentsinfo = resolveFunction("getsignalargumentsinfo"),
				getsignalwhitelist = resolveFunction("getsignalwhitelist"),
				getsimulationradius = resolveFunction("getsimulationradius"),
				gettenv = resolveFunction("gettenv"),
				httpget = resolveFunction("httpget"),
				is_parallel = resolveFunction("is_parallel"),
				isourthread = resolveFunction("isourthread"),
				makereadonly = resolveFunction("makereadonly"),
				makewritable = resolveFunction("makewritable"),
				rconsoleerror = resolveFunction("rconsoleerror"),
				run_on_actor = resolveFunction("run_on_actor"),
				run_on_thread = resolveFunction("run_on_thread"),
				saveinstance = resolveFunction("saveinstance"),
				setnamecallmethod = resolveFunction("setnamecallmethod", { "set_namecall_method" }),
				setproximitypromptduration = resolveFunction("setproximitypromptduration"),
			}

			local f = {
				Drawing = {
					Fonts = d,
					new = (resolveFunction("Drawing.new")),
				},
				WebSocket = {
					connect = resolveFunction("WebSocket.connect", { "WebSocket.new", "websocket.connect" }),
				},
				appendfile = resolveFunction("appendfile"),
				base64decode = resolveFunction(
					"base64decode",
					{ "crypt.base64decode", "crypt.base64.decode" }
				),
				base64encode = resolveFunction(
					"base64encode",
					{ "crypt.base64encode", "crypt.base64.encode" }
				),
				cache = {
					invalidate = resolveFunction("cache.invalidate"),
					iscached = resolveFunction("cache.iscached"),
					replace = resolveFunction("cache.replace"),
				},
				checkcaller = resolveFunction("checkcaller"),
				cleardrawcache = resolveFunction("cleardrawcache"),
				clearteleportqueue = resolveFunction(
					"clearteleportqueue",
					{ "clear_teleport_queue", "clearqueueonteleport" }
				),
				clonefunction = resolveFunction("clonefunction"),
				cloneref = resolveFunction("cloneref", { "clonereference" }),
				compareinstances = resolveFunction("compareinstances"),
				crypt = {
					base64decode = resolveFunction("crypt.base64decode"),
					base64encode = resolveFunction("crypt.base64encode"),
					decrypt = resolveFunction("crypt.decrypt"),
					encrypt = resolveFunction("crypt.encrypt"),
					generatebytes = resolveFunction("crypt.generatebytes"),
					generatekey = resolveFunction("crypt.generatekey"),
					hash = resolveFunction("crypt.hash"),
					hmac = resolveFunction("crypt.hmac"),
					lz4compress = resolveFunction("crypt.lz4compress"),
					lz4decompress = resolveFunction("crypt.lz4decompress"),
					random = resolveFunction("crypt.random"),
				},
				debug = {
					getcallstack = resolveFunction("debug.getcallstack", { "getcallstack" }),
					getconstant = resolveFunction("debug.getconstant", { "getconstant" }),
					getconstants = resolveFunction("debug.getconstants", { "getconstants" }),
					getinfo = resolveFunction("debug.getinfo", { "getinfo" }),
					getproto = resolveFunction("debug.getproto", { "getproto" }),
					getprotos = resolveFunction("debug.getprotos", { "getprotos" }),
					getregistry = resolveFunction("debug.getregistry", { "getregistry" }),
					getsafeenv = resolveFunction("debug.getsafeenv", { "debug.isuntouched" }),
					getstack = resolveFunction("debug.getstack", { "getstack" }),
					getupvalue = resolveFunction("debug.getupvalue", { "getupvalue" }),
					getupvalues = resolveFunction("debug.getupvalues", { "getupvalues" }),
					isvalidlevel = resolveFunction("debug.isvalidlevel", { "debug.validlevel" }),
					setconstant = resolveFunction("debug.setconstant", { "setconstant" }),
					setinfo = resolveFunction("debug.setinfo", { "setinfo" }),
					setname = resolveFunction("debug.setname", { "setname" }),
					setsafeenv = resolveFunction("debug.setsafeenv", { "debug.setuntouched" }),
					setstack = resolveFunction("debug.setstack", { "setstack" }),
					setupvalue = resolveFunction("debug.setupvalue", { "setupvalue" }),
				},
				decompile = resolveFunction("decompile"),
				delfile = resolveFunction("delfile"),
				delfolder = resolveFunction("delfolder"),
				dofile = resolveFunction("dofile"),
				filtergc = resolveFunction("filtergc"),
				fireclickdetector = resolveFunction("fireclickdetector"),
				fireproximityprompt = resolveFunction("fireproximityprompt"),
				firesignal = resolveFunction("firesignal"),
				firetouchinterest = resolveFunction("firetouchinterest"),
				getcallbackvalue = resolveFunction("getcallbackvalue", { "getcallbackmember" }),
				getcallingscript = resolveFunction("getcallingscript"),
				getconnections = resolveFunction("getconnections"),
				getcustomasset = resolveFunction("getcustomasset"),
				getfflag = resolveFunction("getfflag", { "getfastflag" }),
				getfpscap = resolveFunction("getfpscap"),
				getfunctionhash = resolveFunction("getfunctionhash"),
				getgc = resolveFunction("getgc"),
				getgenv = resolveFunction("getgenv"),
				gethiddenproperties = resolveFunction("gethiddenproperties"),
				gethiddenproperty = resolveFunction("gethiddenproperty", { "gethiddenprop" }),
				gethui = resolveFunction("gethui", { "get_hidden_gui" }),
				gethwid = resolveFunction("gethwid", { "get_hwid", "get_user_identifier" }),
				getinstances = resolveFunction("getinstances"),
				getloadedmodules = resolveFunction("getloadedmodules"),
				getnamecallmethod = resolveFunction("getnamecallmethod", { "get_namecall_method" }),
				getnilinstances = resolveFunction("getnilinstances"),
				getproperties = resolveFunction("getproperties"),
				getrawmetatable = resolveFunction("getrawmetatable", { "debug.getmetatable" }),
				getreg = resolveFunction("getreg", { "debug.getregistry", "getregistry" }),
				getrenderproperty = resolveFunction("getrenderproperty"),
				getrenv = resolveFunction("getrenv"),
				getrunningscripts = resolveFunction("getrunningscripts"),
				getscriptbytecode = resolveFunction("getscriptbytecode", { "dumpstring" }),
				getscriptclosure = resolveFunction("getscriptclosure", { "getscriptfunction" }),
				getscriptfromthread = resolveFunction("getscriptfromthread"),
				getscripthash = resolveFunction("getscripthash"),
				getscripts = resolveFunction("getscripts"),
				getscriptthread = resolveFunction("getscriptthread"),
				getsenv = resolveFunction("getsenv"),
				getthreadidentity = resolveFunction(
					"getthreadidentity",
					{ "getidentity", "getthreadcontext", "get_thread_identity" }
				),
				hookfunction = resolveFunction("hookfunction", { "hookfunc", "replaceclosure" }),
				hookmetamethod = resolveFunction("hookmetamethod"),
				identifyexecutor = resolveFunction("identifyexecutor", { "getexecutorname" }),
				iscclosure = resolveFunction("iscclosure"),
				isexecutorclosure = resolveFunction("isexecutorclosure"),
				isfile = resolveFunction("isfile"),
				isfolder = resolveFunction("isfolder"),
				isfunctionhooked = resolveFunction("isfunctionhooked"),
				islclosure = resolveFunction("islclosure"),
				isnetworkowner = resolveFunction("isnetworkowner"),
				isnewcclosure = resolveFunction("isnewcclosure"),
				isrbxactive = resolveFunction("isrbxactive", { "isgameactive", "iswindowactive" }),
				isreadonly = resolveFunction("isreadonly", { "is_readonly" }),
				isrenderobj = resolveFunction("isrenderobj"),
				isscriptable = resolveFunction("isscriptable"),
				keypress = resolveFunction("keypress"),
				keyrelease = resolveFunction("keyrelease"),
				keytap = resolveFunction("keytap", { "keyclick" }),
				listfiles = resolveFunction("listfiles"),
				loadfile = resolveFunction("loadfile"),
				loadstring = resolveFunction("loadstring"),
				lz4compress = resolveFunction("lz4compress", { "crypt.lz4compress" }),
				lz4decompress = resolveFunction("lz4decompress", { "crypt.lz4decompress" }),
				makefolder = resolveFunction("makefolder"),
				messagebox = resolveFunction("messagebox"),
				mouse1click = resolveFunction("mouse1click"),
				mouse1press = resolveFunction("mouse1press"),
				mouse1release = resolveFunction("mouse1release"),
				mouse2click = resolveFunction("mouse2click"),
				mouse2press = resolveFunction("mouse2press"),
				mouse2release = resolveFunction("mouse2release"),
				mousemoveabs = resolveFunction("mousemoveabs"),
				mousemoverel = resolveFunction("mousemoverel"),
				mousescroll = resolveFunction("mousescroll"),
				newcclosure = resolveFunction("newcclosure"),
				newlclosure = resolveFunction("newlclosure"),
				oth = {
					get_original_thread = resolveFunction("oth.get_original_thread"),
					get_root_callback = resolveFunction("oth.get_root_callback"),
					hook = resolveFunction("oth.hook"),
					is_hook_thread = resolveFunction("oth.is_hook_thread"),
					unhook = resolveFunction("oth.unhook"),
				},
				potassium = e,
				queueonteleport = resolveFunction("queueonteleport", { "queue_on_teleport" }),
				raknet = {
					add_receive_hook = resolveFunction("raknet.add_receive_hook"),
					add_send_hook = resolveFunction("raknet.add_send_hook"),
					remove_receive_hook = resolveFunction("raknet.remove_receive_hook"),
					remove_send_hook = resolveFunction("raknet.remove_send_hook"),
					send = resolveFunction("raknet.send"),
				},
				rconsoleclear = resolveFunction("rconsoleclear"),
				rconsolecreate = resolveFunction("rconsolecreate"),
				rconsoledestroy = resolveFunction("rconsoledestroy"),
				rconsoleinfo = resolveFunction("rconsoleinfo"),
				rconsoleinput = resolveFunction("rconsoleinput"),
				rconsoleprint = resolveFunction("rconsoleprint"),
				rconsolesettitle = resolveFunction("rconsolesettitle", { "rconsolename" }),
				rconsolewarn = resolveFunction("rconsolewarn"),
				readfile = resolveFunction("readfile"),
				replicatesignal = resolveFunction("replicatesignal"),
				request = resolveFunction("request", { "http_request", "http.request" }),
				restorefunction = resolveFunction("restorefunction"),
				setclipboard = resolveFunction("setclipboard", { "toclipboard" }),
				setfflag = resolveFunction("setfflag", { "setfastflag" }),
				setfpscap = resolveFunction("setfpscap"),
				sethiddenproperty = resolveFunction("sethiddenproperty", { "sethiddenprop" }),
				setrawmetatable = resolveFunction("setrawmetatable", { "debug.setmetatable" }),
				setrbxclipboard = resolveFunction("setrbxclipboard"),
				setreadonly = resolveFunction("setreadonly", { "set_readonly" }),
				setrenderproperty = resolveFunction("setrenderproperty"),
				setscriptable = resolveFunction("setscriptable"),
				setsimulationradius = resolveFunction("setsimulationradius"),
				setstackhidden = resolveFunction("setstackhidden"),
				setthreadidentity = resolveFunction(
					"setthreadidentity",
					{ "setidentity", "setthreadcontext", "set_thread_identity" }
				),
				writefile = resolveFunction("writefile"),
			}

			return f
		end
		function a.b()
			local b = a.cache.b
			if not b then
				b = { c = __modImpl() }
				a.cache.b = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			return {}
		end
		function a.c()
			local b = a.cache.c
			if not b then
				b = { c = __modImpl() }
				a.cache.c = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.c()

			local b = a.b()

			local c, d = pcall(function()
				local c = b.request({ Url = "https://sirius.menu/gen2", Method = "GET" })
				assert(c.Success, "Rayfield download failed (HTTP " .. tostring(c.StatusCode) .. ")")
				return c.Body
			end)
			assert(c, "Kepler could not download Rayfield Gen2: " .. tostring(d))
			local e, f = b.loadstring(d)
			assert(e, "Kepler could not compile Rayfield Gen2: " .. tostring(f))
			return (e())
		end
		function a.d()
			local b = a.cache.d
			if not b then
				b = { c = __modImpl() }
				a.cache.d = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.c()

			return {}
		end
		function a.e()
			local b = a.cache.e
			if not b then
				b = { c = __modImpl() }
				a.cache.e = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.e()
			a.c()

			return function(b)
				local c = b.window

				local d = 0

				local e = c:CreateTab({ name = "Example", icon = "sparkles" })
				local f

				e:CreateButton({
					name = "Update text",
					callback = function()
						d += 1
						if f then
							f:Set(string.format("Button pressed %d times.", d))
						end
					end,
				})

				f = e:CreateText({ name = "Result", text = "Press Update text to begin." })

				return {
					tab = e,
				}
			end
		end
		function a.f()
			local b = a.cache.f
			if not b then
				b = { c = __modImpl() }
				a.cache.f = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			return {}
		end
		function a.g()
			local b = a.cache.g
			if not b then
				b = { c = __modImpl() }
				a.cache.g = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.g()

			local b = {}
			b.names = { "Perfect", "Great", "OK", "Miss" }

			function b.finite(c)
				return type(c) == "number" and c == c and math.abs(c) < math.huge
			end

			function b.validate(c)
				for d, e in ipairs({ c.early, c.late }) do
					if type(e) ~= "table" then
						return false
					end
					local f = 0
					for g = 1, 3 do
						if not b.finite(e[g]) or e[g] <= f + 2 then
							return false
						end
						f = e[g]
					end
				end
				return true
			end

			function b.probabilities(c)
				local d = {}
				local e = 0
				for f, g in ipairs(b.names) do
					local h = c[g]
					h = b.finite(h) and math.max(0, math.min(100, h)) or 0
					d[g], e = h, e + h
				end
				if e == 0 then
					return nil
				end
				for f, g in pairs(d) do
					d[f] = g / e
				end
				return d
			end

			function b.sample(c, d, e)
				local f = b.probabilities(c)
				if not f then
					return nil
				end
				assert(b.validate(d), "Timing windows must increase: Perfect < Great < OK")
				local g, h, i = e(), 0, "Miss"
				for j, k in ipairs(b.names) do
					h = h + f[k]
					if g < h then
						i = k
						break
					end
				end
				if i == "Miss" then
					local j = { rating = i, skip = true, offset = nil }
					return j
				end
				local j = i == "Perfect" and 1 or (i == "Great" and 2 or 3)
				local k = e() < 0.5
				local l = k and d.early or d.late
				local m = j == 1 and 0 or l[j - 1]
				local n = l[j]

				local o = math.min(6, (n - m) * 0.2)
				m, n = m + o, n - o
				local p = m + (n - m) * (e() + e()) / 2
				return { rating = i, offset = k and -p or p, skip = false }
			end

			return b
		end
		function a.h()
			local b = a.cache.h
			if not b then
				b = { c = __modImpl() }
				a.cache.h = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.b()
			a.a()

			return function(c)
				if type(c) ~= "function" then
					return {}
				end
				local d, e = pcall(b.debug.getupvalues, c)
				return if d and type(e) == "table" then e else {}
			end
		end
		function a.i()
			local b = a.cache.i
			if not b then
				b = { c = __modImpl() }
				a.cache.i = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.h()
			a.g()

			local c = a.b()
			local d = a.i()

			local e = {}
			e.__index = e

			local function findGameMethod(f, g)
				if type(f) ~= "table" then
					return nil
				end
				local h = rawget(f, g)
				if type(h) == "function" then
					return h
				end
				return nil
			end

			local function tryInvokeGameMethod(f, g, ...)
				local h = findGameMethod(f, g)
				if not h then
					return nil
				end
				local i, j = pcall(h, f, ...)
				if i then
					return j
				end
				return nil
			end

			function e.new(f)
				return setmetatable({
					config = f,
					clients = {},
					inputOwners = {},
					candidates = {},
					status = "Waiting for autoplay",
					generation = 0,
					scanning = false,
					nextScan = 0,
				}, e)
			end

			function e.cancel(f)
				f.generation = f.generation + 1
				f.scanning, f.nextScan = false, 0
				f.list, f.current, f.factor, f.probe = nil, nil, nil, nil
				f.candidates = {}
				f.localSlot = nil
				f.session, f.trackReadAt = nil, nil
				f.timingReady, f.discoveryError, f.windowReadAt = false, nil, nil
			end

			function e.discover(f, g)
				if #f.clients > 0 or f.scanning or g < f.nextScan then
					return
				end
				f.scanning, f.nextScan = true, g + 5
				local h = f.generation
				task.spawn(function()
					local i, j = pcall(function()
						c.debug.getupvalues(function() end)
						local i = {}
						local j, k = c.getgc(true), os.clock()

						for l = #j, 1, -1 do
							local m = j[l]
							if h ~= f.generation then
								return false
							end
							if findGameMethod(m, "get_game") and findGameMethod(m, "is_game_finished") then
								table.insert(i, m)
								break
							end
							if l % 4096 == 0 and os.clock() - k > 0.004 then
								task.wait()
								k = os.clock()
							end
						end
						if h == f.generation then
							f.clients = i
						end
						return true
					end)
					if h == f.generation then
						f.scanning = false
						f.discoveryError = not i and ("Discovery failed: " .. tostring(j)) or nil
					end
				end)
			end

			function e.game(f)
				local g
				for h, i in ipairs(f.clients) do
					local j = tryInvokeGameMethod(i, "get_game")
					if j then
						if g and g ~= j then
							return nil
						end
						g = j
					end
				end
				if not g then
					return nil
				end
				for h, i in ipairs({ "is_spectate", "is_preview_game", "is_tutorial" }) do
					if tryInvokeGameMethod(g, i) ~= false then
						return nil
					end
				end
				local h = g._game_join
				if
					tryInvokeGameMethod(h, "is_game_finished") ~= false
					or tryInvokeGameMethod(h, "is_game_early_quit") ~= false
				then
					return nil
				end
				return g
			end

			function e.bind(f, g)
				f.current, f.list, f.factor, f.probe = g, nil, nil, nil
				f.candidates, f.timingReady, f.windowReadAt = {}, false, nil
				f.localSlot = nil
				f.session, f.trackReadAt = nil, nil
				f.input = g._input
				assert(
					findGameMethod(f.input, "input_began") and findGameMethod(f.input, "input_ended"),
					"Current game input is unavailable"
				)
				f.config.keys = {}
				for h = 1, 4 do
					local i = tryInvokeGameMethod(f.input, "get_key_display_str", h - 1)
					local j, k = pcall(function()
						return (Enum.KeyCode)[i]
					end)
					assert(j and k, "Cannot resolve in-game binding for lane " .. h)
					f.config.keys[h] = k
				end
				local h = {}
				for i, j in ipairs(f.config.keys or {}) do
					assert(not h[j], "Each lane must have a different key")
					h[j] = true
				end
				f:refreshTracks()
			end

			local function readLocalGameSlot(f)
				local g = d(findGameMethod(f, "set_local_game_slot"))
				local h = g[1]
				if #g == 1 and b.finite(h) and h >= 1 and h % 1 == 0 then
					return h
				end
				return nil
			end

			function e.refreshTracks(f)
				local g = assert(f.current)
				local h = readLocalGameSlot(g)
				local i = {}
				local j = {}
				for k, l in pairs(d(g.update)) do
					local m = tryInvokeGameMethod(l, "get_table")
					if type(m) == "table" then
						for n, o in pairs(m) do
							if n ~= h then
								continue
							end
							for p, q in
								pairs(
									d(findGameMethod(o, "tracksystem_update_all_active_notes_display_mode"))
								)
							do
								if not i[q] and findGameMethod(q, "get") and findGameMethod(q, "count") then
									i[q] = true
									table.insert(j, q)
								end
							end
						end
					end
				end
				local k = h ~= f.localSlot or #j ~= #f.candidates
				for l, m in ipairs(f.candidates) do
					if not i[m] then
						k = true
						break
					end
				end
				if k then
					f.localSlot = h
					f.candidates = j
					f.list, f.probe, f.session = nil, nil, nil
					f.timingReady, f.windowReadAt = false, nil
				end
			end

			function e.windows(f, g)
				for h, i in pairs({ findGameMethod(g, "cons") }) do
					if type(i) == "function" then
						for j, k in pairs(d(i)) do
							if type(k) == "table" and #k == 6 then
								local l = true
								for m = 1, 6 do
									if not b.finite(k[m]) then
										l = false
										break
									end
								end
								if l and k[3] > 0 and k[4] < 0 then
									local m = {

										early = { -k[4], -k[5], -k[6] },
										late = { k[3], k[2], k[1] },
									}
									if b.validate(m) then
										return m
									end
								end
							end
						end
					end
				end
				return nil
			end

			function e.read(f, g, h)
				local i = tryInvokeGameMethod(g, "count")
				if not b.finite(i) or i < 0 or i % 1 ~= 0 or i > 20000 then
					return nil
				end
				local j = {}
				for k = 1, math.min(i, h or i) do
					local l = tryInvokeGameMethod(g, "get", k)
					local m = tryInvokeGameMethod(l, "get_state")

					if m == 0 or m == 1 then
						local n = tryInvokeGameMethod(l, "get_track_index")
						local o = tryInvokeGameMethod(l, "get_note_index")
						local p = tryInvokeGameMethod(l, "get_delta_time_from_hit_time")
						if not b.finite(n) or not b.finite(o) or not b.finite(p) then
							return nil
						end
						local q, r
						if findGameMethod(l, "get_tail_hit_time") then
							local s = d(l.get_tail_hit_time)
							local t = tryInvokeGameMethod(l, "get_tail_hit_time")

							assert(
								b.finite(s[1])
									and b.finite(s[2])
									and s[2] >= 0
									and b.finite(t)
									and math.abs(s[1] + s[2] - t) < 0.01,
								"Hold timing layout changed"
							)
							r = s[2]
							q = m == 0 and (p - r)
								or tryInvokeGameMethod(l, "get_delta_time_from_release_time")
							assert(b.finite(q), "Hold tail clock is unavailable")
						end
						-- FIX: get_track_index is 0-based; shift to 1-based so lane aligns with keys[lane]
						table.insert(j, {
							id = tostring(n) .. ":" .. tostring(o),
							object = l,
							state = m,
							lane = n + 1,
							raw = p,
							remaining = -p,
							rawTail = q,
							isHold = r ~= nil,
						})
					end
				end
				return j
			end

			function e.calibrate(f, g)
				if not f.probe then
					local h = { at = g, lists = {} }
					for i, j in ipairs(f.candidates) do
						local k = f:read(j, 32)
						if k and #k > 0 then
							local l = {}
							for m, n in ipairs(k) do
								if n.state == 0 then
									l[n.id] = n.raw
								end
							end
							h.lists[j] = l
						end
					end
					f.probe = h
					return
				end
				if g - f.probe.at < 0.2 then
					return
				end
				local h, i = g - f.probe.at, {}
				for j, k in pairs(f.probe.lists) do
					local l, m = f:read(j, 32), 0
					if l then
						for n, o in ipairs(l) do
							if o.state == 0 and k[o.id] then
								local p = (o.raw - k[o.id]) / h
								if p > 700 and p < 1300 then
									m = m + 1
								end
							end
						end
					end
					if m >= 2 then
						table.insert(i, j)
					end
				end
				f.probe = nil
				if #i == 1 then
					f.list, f.factor = i[1], -1
					f.session = {}
					f.status = "Ready"
				else
					f.status = #i > 1 and "Multiple moving note streams; autoplay paused"
						or "Waiting for moving notes to calibrate"
				end
			end

			function e.snapshot(f, g)
				local h = f:game()
				if not h then
					f.current, f.list, f.probe = nil, nil, nil
					f.session, f.trackReadAt = nil, nil
					f:discover(g)
					f.status = f.discoveryError or "Waiting for a playable song"
					return nil, {}
				end

				if h ~= f.current then
					f:bind(h)
				end

				if not f.trackReadAt or g - f.trackReadAt >= 0.5 then
					f.trackReadAt = g
					f:refreshTracks()
				end

				if not f.list then
					if not f.localSlot then
						f.status = "Waiting for the local player slot"
						return nil, {}
					end
					f:calibrate(g)
					return nil, {}
				end

				local i = f:read(assert(f.list))
				assert(i, "Active note list changed structure")

				if i[1] and (not f.windowReadAt or g - f.windowReadAt >= 0.5) then
					f.windowReadAt = g
					local j = f:windows(i[1].object)
					assert(j, "Could not read live judgement windows")
					f.config.windows, f.timingReady = j, true
				end

				if not f.timingReady then
					f.status = "Waiting for live judgement windows"
					return nil, {}
				end

				for j, k in ipairs(i) do
					assert(k.lane >= 1 and k.lane <= 4, "Unexpected lane number")
					k.remaining, k.tail = -k.raw, k.rawTail and -k.rawTail or nil
					k.alreadyHit = k.state == 1
				end

				f.status = "Playing"

				return f.session, i
			end

			function e.press(f, g, h)
				local i = assert(f.input, "Game input module is unavailable")
				assert(not f.inputOwners[g], "Release the previous lane input before pressing again")

				f.inputOwners[g] = i
				i:input_began(h)
			end

			function e.release(f, g, h)
				local i = assert(f.inputOwners[g] or f.input, "Game input module is unavailable")
				i:input_ended(h)
				f.inputOwners[g] = nil
			end

			return e
		end
		function a.j()
			local b = a.cache.j
			if not b then
				b = { c = __modImpl() }
				a.cache.j = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.h()
			a.g()

			local c = {}
			c.__index = c

			function c.new(d, e, f)
				return setmetatable({
					config = d,
					input = e,
					random = f,
					plans = {},
					held = {},
					stats = { Perfect = 0, Great = 0, OK = 0, Miss = 0, late = 0, blocked = 0, recovered = 0 },
					enabled = false,
				}, c)
			end

			function c.release(d, e)
				local f = d.held[e]
				if f then
					d.input.release(e, f.key)
					d.held[e] = nil
				end
			end

			function c.reset(d, e)
				local f
				for g = 1, 4 do
					local h, i = pcall(function()
						d:release(g)
					end)
					if not h then
						f = i
					end
				end
				d.plans, d.session = {}, e
				if f then
					error(f)
				end
			end

			function c.setEnabled(d, e)
				d.enabled = e
				if not e then
					d:reset(nil)
				end
			end

			function c.step(d, e, f, g)
				if not d.enabled then
					return
				end
				local h = d.session ~= e
				if h then
					d:reset(e)
				end
				if not e then
					return
				end
				local i = b.probabilities(d.config.weights)
				if not i then
					d:reset(e)
					return
				end
				assert(
					b.validate(d.config.windows),
					"JudgementTiming windows must increase: Perfect < Great < OK"
				)
				local j = { {}, {}, {}, {} }
				for k, l in ipairs(f) do
					if l.lane >= 1 and l.lane <= 4 then
						local m = d.plans[l.id]
						if not m then
							local n = assert(b.sample(d.config.weights, d.config.windows, d.random))
							m = {
								sample = n,
								done = (h and l.remaining < 0) or l.alreadyHit == true,
								lastSeen = g,
							}
							d.plans[l.id] = m
						end
						m.lastSeen = g
						table.insert(j[l.lane], { note = l, plan = m })
					end
				end
				for k = 1, 4 do
					local l = j[k]
					table.sort(l, function(m, n)
						return m.note.remaining < n.note.remaining
					end)
					local m = d.held[k]
					if m then
						if m.hold then
							for n, o in ipairs(l) do
								if o.note.id == m.id and o.note.tail then
									m.untilTime = g + o.note.tail + m.tailOffset
									break
								end
							end
						end
						if g >= m.untilTime then
							d:release(k)
						end
					end
					for n, o in ipairs(l) do
						local p, q = o.note, o.plan
						if not q.done then
							local r = q.sample
							if r.skip then
								if p.remaining <= 0 then
									q.done = true
									d.stats.Miss = d.stats.Miss + 1
								end
							else
								local s = assert(r.offset, "Playable note requires a timing offset")
								local t = p.remaining + s - (d.config.inputLeadMs or 0)
								if t <= 0 then
									if d.held[k] and d.held[k].hold and t >= -d.config.maxLateness then
										break
									end
									q.done = true
									if d.held[k] and d.held[k].hold then
										d.stats.blocked = d.stats.blocked + 1
									elseif
										-p.remaining + (d.config.inputLeadMs or 0)
										>= d.config.windows.late[3] - 6
									then
										d.stats.late = d.stats.late + 1
									else
										if t < -d.config.maxLateness then
											d.stats.recovered = d.stats.recovered + 1
										end
										d:release(k)

										local u = d.config.keys[k]
										local v = p.isHold == true
											or (p.tail ~= nil and p.tail - p.remaining > 5)
										local w = (d.random() + d.random() - 1) * 4
										d.held[k] = {
											id = p.id,
											key = u,
											hold = v,
											tailOffset = w,
											untilTime = g
												+ (
													v and math.max(1, assert(p.tail) + w)
													or (28 + 32 * (d.random() + d.random()) / 2)
												),
										}
										d.input.press(k, u)
										d.stats[r.rating] = d.stats[r.rating] + 1
									end

									break
								else
									break
								end
							end
						end
					end
				end

				for k, l in pairs(d.plans) do
					if g - l.lastSeen > 10000 then
						d.plans[k] = nil
					end
				end
			end

			return c
		end
		function a.k()
			local b = a.cache.k
			if not b then
				b = { c = __modImpl() }
				a.cache.k = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = {}

			function b.observe(c, d)
				table.insert(c, math.clamp(d * 1000, 1, 250))
				if #c > 15 then
					table.remove(c, 1)
				end
				local e = table.clone(c)
				table.sort(e)
				return e[math.ceil(#e / 2)]
			end

			return b
		end
		function a.l()
			local b = a.cache.l
			if not b then
				b = { c = __modImpl() }
				a.cache.l = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.b()

			local c = {}

			return function(d)
				local e = c[d]
				if e then
					return e
				end
				local f = game:GetService(d)
				local g, h = pcall(b.cloneref, f)
				local i = if g and typeof(h) == typeof(f) then h else f
				c[d] = i
				return i
			end
		end
		function a.m()
			local b = a.cache.m
			if not b then
				b = { c = __modImpl() }
				a.cache.m = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.j()
			local c = a.k()
			local d = a.h()
			local e = a.l()
			a.c()
			a.g()
			a.e()

			local f = a.m()

			local function formatDistribution(g)
				local h = d.probabilities(g)
				if not h then
					return "Paused — raise any judgement weight to resume."
				end
				local i = {}
				for j, k in ipairs(d.names) do
					if h[k] > 0 then
						table.insert(i, string.format("%s %.1f%%", k, h[k] * 100))
					end
				end
				return table.concat(i, "  ·  ")
			end

			return function(g)
				local h = g.window

				local i = {
					weights = { Perfect = 85, Great = 12, OK = 2, Miss = 1 },

					windows = { early = { 20, 95, 235 }, late = { 40, 190, 430 } },
					keys = { Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.F },
					maxLateness = 35,
				}

				local j = {}
				local k = 0
				local l = table.clone(i.weights)
				local m

				local n
				local o
				local p
				local q
				local r
				local s

				local t = b.new(i)
				local u = Random.new()
				local v = c.new(i, {
					press = function(v, w)
						t:press(v, w)
					end,
					release = function(v, w)
						t:release(v, w)
					end,
				}, function()
					return u:NextNumber()
				end)

				local function stopAutoplay()
					v.enabled = false
					t:cancel()
					if n then
						n:Set(false, true)
					end

					v:reset(nil)
				end
				g:trackCleanup(stopAutoplay)

				local function setAutoplayEnabled(w)
					if not g.alive then
						return
					end
					if not w then
						stopAutoplay()
					elseif not v.enabled then
						v.enabled = true
					end
				end

				local function refreshDistribution()
					local w = formatDistribution(i.weights)
					if o and w ~= m then
						m = w
						o:Set(w)
					end
				end

				local function applyWeights(w)
					i.weights.Perfect = w.Perfect
					i.weights.Great = w.Great
					i.weights.OK = w.OK
					i.weights.Miss = w.Miss
					assert(p):Set(w.Perfect)
					assert(q):Set(w.Great)
					assert(r):Set(w.OK)
					assert(s):Set(w.Miss)
					refreshDistribution()
				end

				local function updateAutoplay(w)
					if not g.alive then
						return
					end
					if h.unloaded then
						g:unload()
						return
					end
					local x = os.clock()

					i.inputLeadMs = e.observe(j, w) * 1.5
					local y, z = pcall(function()
						if not v.enabled then
							return true
						end
						if not d.probabilities(i.weights) then
							v:reset(nil)
							return true
						end
						local y, z = t:snapshot(x)
						if not g.alive then
							return true
						end
						v:step(y, z, x * 1000)
						return true
					end)
					if not g.alive then
						return
					end
					if not y then
						local A, B = pcall(function()
							stopAutoplay()
							return true
						end)
						local C = not A and ("\nKey release failed: " .. tostring(B)) or ""
						local D = "Stopped: " .. tostring(z) .. C

						g:notify("Autoplay stopped", D)
					end
					if x - k >= 0.25 then
						k = x
						refreshDistribution()
					end
				end

				local w = h:CreateTab({ name = "RoBeats", icon = "music-2" })
				n = w:CreateToggle({
					name = "Autoplay",
					icon = "play",
					value = false,
					forgetState = true,
					callback = function(x)
						setAutoplayEnabled(x)
					end,
				})
				local x = w:CreateGroup({ direction = "row" })
				w:CreateSection({ name = "Judgement mix" })
				local y = w:CreateGroup({ direction = "row" })
				p = y:CreateSlider({
					name = "Perfect",
					icon = "sparkles",
					range = { 0, 100 },
					increment = 1,
					value = i.weights.Perfect,
					flag = "RoBeats_Weight_Perfect",
					callback = function(z)
						i.weights.Perfect = z
					end,
				})

				q = y:CreateSlider({
					name = "Great",
					icon = "check",
					range = { 0, 100 },
					increment = 1,
					value = i.weights.Great,
					flag = "RoBeats_Weight_Great",
					callback = function(z)
						i.weights.Great = z
					end,
				})

				local z = w:CreateGroup({ direction = "row" })
				r = z:CreateSlider({
					name = "OK",
					icon = "circle",
					range = { 0, 100 },
					increment = 1,
					value = i.weights.OK,
					flag = "RoBeats_Weight_OK",
					callback = function(A)
						i.weights.OK = A
					end,
				})

				s = z:CreateSlider({
					name = "Miss",
					icon = "x",
					range = { 0, 100 },
					increment = 1,
					value = i.weights.Miss,
					flag = "RoBeats_Weight_Miss",
					callback = function(A)
						i.weights.Miss = A
					end,
				})

				o = w:CreateText({ name = "Target distribution", text = "", icon = "sliders-horizontal" })
				x:CreateButton({
					name = "All perfect",
					icon = "sparkles",
					callback = function()
						applyWeights({ Perfect = 100, Great = 0, OK = 0, Miss = 0 })
					end,
				})
				x:CreateButton({
					name = "Reset mix",
					callback = function()
						applyWeights(l)
					end,
				})
				refreshDistribution()

				g:trackConnection(f("RunService").Heartbeat:Connect(updateAutoplay))

				return {
					tab = w,
					stop = stopAutoplay,
					testingProps = {
						config = i,
						adapter = t,
						engine = v,
					},
				}
			end
		end
		function a.n()
			local b = a.cache.n
			if not b then
				b = { c = __modImpl() }
				a.cache.n = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.a()

			return {}
		end
		function a.o()
			local b = a.cache.o
			if not b then
				b = { c = __modImpl() }
				a.cache.o = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.b()
			local c = a.m()

			local d = type(restorefunction) == "function"
			local e = {}

			function e.submitFromGameCallback(f, g)
				local h, i = pcall(b.getconnections, c("RunService").Heartbeat)
				if not d or not h then
					return false,
						"Bot execution requires game callback inspection and reversible function hooks."
				end
				local j
				for k, l in ipairs(i) do
					local m = l.Function
					if m then
						local n, o = pcall(b.debug.getconstants, m)
						if n then
							for p, q in pairs(o) do
								if q == "MovingPlatformsFolder" then
									j = m
								end
							end
						end
					end
				end
				if not j then
					return false,
						"An unmodified game heartbeat callback was not found; no move was submitted."
				end
				local k, l = pcall(b.isfunctionhooked, j)
				if not k then
					return false,
						"Bot execution requires game callback inspection and reversible function hooks."
				end
				if l then
					return false,
						"An unmodified game heartbeat callback was not found; no move was submitted."
				end
				local m = j
				local n, o = false, false
				local p, q = false, "Game callback did not process the move."
				local r
				local s, t = pcall(function()
					r = b.hookfunction(m, function(...)
						assert(r)(...)
						if n then
							return
						end
						n = true
						b.restorefunction(m)
						if g and not g() then
							q = "Move cancelled before game callback submission."
						else
							p, q = pcall(f)
						end
						o = true
					end)
				end)
				if not s then
					return false, "Game callback hook failed: " .. tostring(t)
				end
				local u = os.clock() + 5
				while not o do
					if not n and ((g and not g()) or os.clock() >= u) then
						n = true
						b.restorefunction(m)
						return false,
							"Game callback submission expired or was cancelled; no move was submitted."
					end
					task.wait(0.05)
				end
				return p, tostring(q)
			end

			return e
		end
		function a.p()
			local b = a.cache.p
			if not b then
				b = { c = __modImpl() }
				a.cache.p = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			local b = a.p()
			local c = a.b()
			local d = a.m()
			local e = a.i()
			local f = d("Players")
			local g = d("Workspace")

			local h = f.LocalPlayer

			local i = {}

			i.Pieces = {
				Pawn = "p",
				Knight = "n",
				Bishop = "b",
				Rook = "r",
				Queen = "q",
				King = "k",
			}

			local function samePosition(j, k)
				return j ~= nil and k ~= nil and j[1] == k[1] and j[2] == k[2]
			end

			local function getPieceAtPosition(j, k)
				for l, m in pairs(j.whitePieces or {}) do
					if m.position and samePosition(m.position, k) then
						return m
					end
				end

				for l, m in pairs(j.blackPieces or {}) do
					if m.position and samePosition(m.position, k) then
						return m
					end
				end

				return nil
			end

			local function isUnmovedPiece(j, k, l, m)
				local n = getPieceAtPosition(j, k)
				return n ~= nil and n.Name == l and n.team == m and n.unmoved == true
			end

			local function readCurrentMatch(j)
				if not j then
					return nil
				end
				if j.currentMatch then
					return j.currentMatch
				end
				if not j.processRound then
					return nil
				end
				for k, l in pairs(e(j.processRound)) do
					if type(l) == "table" and l.tiles and l.boardExists then
						return l
					end
				end
				return nil
			end

			local function hasLocalSeat(j)
				return j ~= nil and j.players ~= nil and (j.players[true] == h or j.players[false] == h)
			end

			local function findChessClient()
				local j, k = pcall(c.getreg)
				if not j or type(k) ~= "table" then
					return nil
				end
				local l
				for m, n in pairs(k) do
					if type(n) == "function" then
						local o, p = pcall(c.iscclosure, n)
						if o and p then
							continue
						end
						for q, r in pairs(e(n)) do
							if type(r) == "table" and type(r.processRound) == "function" then
								local s = r
								if hasLocalSeat(readCurrentMatch(s)) then
									return s
								end
								l = l or s
							end
						end
					end
				end

				return l
			end

			function i.new()
				return {
					client = findChessClient(),
					lastDiscoveryAt = os.clock(),
					refreshClient = i.refreshClient,
					getBoard = i.getBoard,
					isGameInProgress = i.isGameInProgress,
					isBotMatch = i.isBotMatch,
					getLocalTeam = i.getLocalTeam,
					isPlayerTurn = i.isPlayerTurn,
					willCauseDesync = i.willCauseDesync,
					getBoardPiece = i.getBoardPiece,
					readPieceMap = i.readPieceMap,
					readFen = i.readFen,
					hasLegalMove = i.hasLegalMove,
					autoMove = i.autoMove,
				}
			end

			function i.refreshClient(j)
				j.lastDiscoveryAt = os.clock()
				j.client = findChessClient()
				return j.client
			end

			function i.getBoard(j)
				local k = readCurrentMatch(j.client)

				if not hasLocalSeat(k) and os.clock() - (j.lastDiscoveryAt or 0) >= 1 then
					j:refreshClient()
					k = readCurrentMatch(j.client)
				end
				return k
			end

			function i.isGameInProgress(j)
				local k = g:FindFirstChild("Board")
				return k ~= nil and #k:GetChildren() > 0
			end

			function i.isBotMatch(j)
				local k = j:getBoard()

				return k ~= nil and k.players ~= nil and k.players[true] == h and k.players[false] == h
			end

			function i.getLocalTeam(j)
				local k = j:getBoard()
				if not k then
					return nil
				end

				if j:isBotMatch() then
					return if k.botInfo and k.botInfo.team == true then "b" else "w"
				end

				local l = k.players or {}
				for m, n in pairs(l) do
					if n == h then
						return if m then "w" else "b"
					end
				end

				return nil
			end

			function i.isPlayerTurn(j)
				local k = j:getLocalTeam()
				local l = j:getBoard()
				if not k or not l or type(l.activeTeam) ~= "boolean" then
					return false
				end

				return l.activeTeam == (k == "w")
			end

			function i.willCauseDesync(j)
				local k = j:getBoard()
				if not k then
					return true
				end

				local l = j:getLocalTeam()
				return l == nil or type(k.activeTeam) ~= "boolean" or k.activeTeam ~= (l == "w")
			end

			function i.getBoardPiece(j, k)
				local l = j:getBoard()
				if not l then
					return nil
				end

				return getPieceAtPosition(l, k)
			end

			function i.readPieceMap(j)
				local k = j:getBoard()
				if not k then
					return nil
				end

				local l = {}

				local function placePiece(m, n)
					if not (m and m.position and m.Name) then
						return
					end

					local o, p = m.position[1], m.position[2]
					local q = i.Pieces
					local r = q[m.Name]

					if not r then
						return
					end

					l[o] = l[o] or {}
					l[o][p] = n and string.upper(r) or r
				end

				for m, n in pairs(k.whitePieces or {}) do
					placePiece(n, true)
				end

				for m, n in pairs(k.blackPieces or {}) do
					placePiece(n, false)
				end

				return l
			end

			function i.readFen(j)
				local k = j:getBoard()
				if not k or type(k.activeTeam) ~= "boolean" then
					return nil
				end
				local l = j:readPieceMap()
				if not l then
					return nil
				end

				local m = {}

				for n = 8, 1, -1 do
					local o = 0
					local p = {}

					for q = 8, 1, -1 do
						local r = l[q] and l[q][n]

						if r then
							if o > 0 then
								table.insert(p, tostring(o))
								o = 0
							end

							table.insert(p, r)
						else
							o += 1
						end
					end

					if o > 0 then
						table.insert(p, tostring(o))
					end

					table.insert(m, table.concat(p))
				end

				local n = if k.activeTeam then "w" else "b"

				local o = ""
				if isUnmovedPiece(k, { 4, 1 }, "King", true) then
					if isUnmovedPiece(k, { 1, 1 }, "Rook", true) then
						o ..= "K"
					end
					if isUnmovedPiece(k, { 8, 1 }, "Rook", true) then
						o ..= "Q"
					end
				end
				if isUnmovedPiece(k, { 4, 8 }, "King", false) then
					if isUnmovedPiece(k, { 1, 8 }, "Rook", false) then
						o ..= "k"
					end
					if isUnmovedPiece(k, { 8, 8 }, "Rook", false) then
						o ..= "q"
					end
				end

				local p = "-"
				local q = if k.activeTeam then k.whitePieces else k.blackPieces
				for r, s in pairs(q or {}) do
					if s.Name == "Pawn" then
						local t, u = pcall(s.getMoves, s)
						if t then
							for v, w in pairs(u) do
								if w.enpassant and w[1] >= 1 and w[1] <= 8 and (w[2] == 3 or w[2] == 6) then
									p = string.char(105 - w[1]) .. tostring(w[2])
								end
							end
						end
					end
				end
				return table.concat(m, "/")
					.. " "
					.. n
					.. " "
					.. (if o == "" then "-" else o)
					.. " "
					.. p
					.. " 0 1"
			end

			function i.hasLegalMove(j, k, l)
				if not (k and k.getMoves) then
					return false
				end

				for m, n in pairs(k:getMoves()) do
					if samePosition(n, l) then
						return true
					end
				end

				return false
			end

			function i.autoMove(j, k, l, m, n, o, p)
				if n and not n() then
					return false, "The position changed."
				end
				local q = j:getBoard()
				local r = j.client

				if not r then
					return false, "Client not found"
				end

				if not q then
					return false, "Board not found"
				end

				if not r.clickOnTile then
					return false, "clickOnTile not found"
				end

				if j:willCauseDesync() then
					return false, "Not safe to move right now"
				end

				local s = getPieceAtPosition(q, k)
				if not s then
					return false, "No piece at source"
				end

				if not m and s.Name == "Pawn" and (l[2] == 1 or l[2] == 8) then
					return false, "Play this promotion manually and choose the promotion piece."
				end

				if s.team ~= q.activeTeam then
					return false, "Piece is not active team"
				end

				if not j:hasLegalMove(s, l) then
					return false, "Illegal move"
				end
				local t = { q = "Queen", r = "Rook", b = "Bishop", n = "Knight" }
				local u = if m then t[m] else nil
				local v = s.getMoves
				local w
				local x
				local y
				local z
				if u then
					if s.Name ~= "Pawn" or (l[2] ~= 1 and l[2] ~= 8) then
						return false, "Promotion metadata does not match a pawn reaching the last rank."
					end
					local A = false
					for B, C in pairs(s:getMoves()) do
						if samePosition(C, l) and C.promote then
							A = true
						end
					end
					if not A then
						return false,
							"Promotion stopped: the legal move has no promotion metadata. Play manually."
					end

					z = function(B)
						local C = {}
						for D, E in pairs(v(B)) do
							if samePosition(E, l) and E.promote then
								local F = table.clone(E)
								F.promote = table.clone(E.promote)
								assert(F.promote, "Promotion metadata disappeared")
								F.promote.pieceName = u
								table.insert(C, F)
							else
								table.insert(C, E)
							end
						end
						return C
					end

					local B = (getfenv(assert(r.clickOnTile)))
					if type(B.doPromotionInterface) == "function" then
						w = B
						x = B.doPromotionInterface
						y = function(C, D)
							if C ~= s or not samePosition(D, l) then
								return assert(x)(C, D)
							end

							B.doPromotionInterface = x
							return C, assert(u)
						end
						B.doPromotionInterface = y
					end

					s.getMoves = assert(z, "Promotion move provider was not prepared")
				end

				local function performClicks()
					local A = assert(r.clickOnTile, "The game tile handler is unavailable")
					A(r, k[1], k[2])
					task.wait(0.15)
					if n and not n() then
						return "Move cancelled before the destination click."
					end
					if p then
						p()
					end
					A(r, l[1], l[2])
					return "Move attempted"
				end
				local A, B = pcall(function()
					if j:isBotMatch() or w then
						local A, B = b.submitFromGameCallback(performClicks, n)
						if not A then
							error(B, 0)
						end
						return B
					end
					return performClicks()
				end)
				if z and s.getMoves == z then
					s.getMoves = v
				end
				if w and w.doPromotionInterface == y then
					w.doPromotionInterface = x
				end
				if not A then
					return false, "Tile click failed: " .. tostring(B)
				end
				if B ~= "Move attempted" then
					return false, tostring(B)
				end
				if not u then
					return true, "Move attempted"
				end

				local C = os.clock() + 3
				repeat
					if (o and o()) or j:getBoard() ~= q then
						return false, "Promotion verification cancelled. Check the game before retrying."
					end
					local D = j:getBoardPiece(l)
					if D and D.team == s.team and D.Name ~= "Pawn" then
						if D.Name == u then
							return true, "Promotion confirmed: " .. u
						end
						return false,
							"Promotion produced "
								.. D.Name
								.. " instead of "
								.. u
								.. ". Check the board before continuing."
					end
					task.wait(0.1)
				until os.clock() >= C
				return false, "Promotion was not confirmed. Check the selector or board before retrying."
			end

			return i
		end
		function a.q()
			local b = a.cache.q
			if not b then
				b = { c = __modImpl() }
				a.cache.q = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			local b = {}
			b.REQUIRED_REVISION = 1

			function b.compatibilityError(c)
				if c.protocol_revision == b.REQUIRED_REVISION then
					return nil
				end
				local d = if type(c.server_version) == "string"
					then c.server_version
					else "unknown (older build)"
				return `The desktop server ({d}) is incompatible with this client. Download the latest server and restart it. Analysis is paused until a compatible server is running.`
			end

			function b.parseMove(c)
				if type(c) ~= "string" or not string.match(c, "^[a-h][1-8][a-h][1-8][qrbn]?$") then
					return nil, "The engine did not return a playable move."
				end
				return {
					fromPos = { 105 - string.byte(c, 1), assert(tonumber(string.sub(c, 2, 2))) },
					toPos = { 105 - string.byte(c, 3), assert(tonumber(string.sub(c, 4, 4))) },
					promotion = if #c == 5 then (string.sub(c, 5, 5)) else nil,
				},
					nil
			end

			function b.decodeResponse(c, d)
				if type(c) ~= "table" then
					return nil, "The HTTP function returned an invalid response.", nil
				end
				local e = c
				local f = e.Body
				if type(f) ~= "string" or f == "" then
					return nil, "The server returned an empty response.", nil
				end
				local g, h = pcall(d, f)
				if not g or type(h) ~= "table" then
					return nil,
						"The server returned invalid JSON. Check that the chess server is running.",
						nil
				end
				local i = h
				if i.ok == false and type(i.error) == "table" then
					local j = i.error
					return nil,
						tostring(j.message or "The server rejected the request."),
						if type(j.code) == "string" then j.code else nil
				end
				local j = tonumber(e.StatusCode)
				if e.Success == false or not j or j < 200 or j >= 300 then
					return nil, `Server request failed (HTTP {tostring(e.StatusCode)}).`, nil
				end
				if i.ok ~= true then
					return nil, "The server response is missing its success status.", nil
				end
				return i, nil, nil
			end

			function b.delayMs(c, d, e)
				local f = if d and c then c.recommended_delay_ms else e
				if type(f) ~= "number" or f ~= f or math.abs(f) == math.huge then
					f = e
				end
				return math.clamp(f, 0, 120000)
			end

			return b
		end
		function a.r()
			local b = a.cache.r
			if not b then
				b = { c = __modImpl() }
				a.cache.r = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			local b = a.m()
			local c = b("HttpService")
			local d = a.r()

			local e = {}
			e.API_BASE_URL = "http://127.0.0.1:57250/api/v1"

			function e.new(f)
				return {
					request = f,
					requestEndpoint = e.requestEndpoint,
					findBestMove = e.findBestMove,
				}
			end

			function e.requestEndpoint(f, g, h)
				local i = f.request
				if g == "/analyze" then
					local j, k, l = f:requestEndpoint("/status")
					if not j then
						return nil, k, l
					end
				end
				if not i then
					return nil, "Your executor does not provide an HTTP request function.", nil
				end
				local j, k = pcall(function()
					return i({
						Url = e.API_BASE_URL .. g,
						Method = if h then "POST" else "GET",
						Headers = { ["Content-Type"] = "application/json" },
						Body = if h then c:JSONEncode(h) else nil,
					})
				end)
				if not j then
					return nil,
						"Cannot reach the chess server. Open the desktop app and try again. " .. tostring(k),
						nil
				end
				local l, m, n = d.decodeResponse(k, function(l)
					return c:JSONDecode(l)
				end)
				if l and g == "/status" then
					local o = d.compatibilityError(l)
					if o then
						if f.onIncompatible then
							f.onIncompatible(o)
						end
						return nil, o, "incompatible_server"
					end
				end
				return l, m, n
			end

			function e.findBestMove(f, g, h)
				local function analysisFailure(i, j)
					return { success = false, reason = i or "Unknown server error", code = j }
				end
				if not g:isGameInProgress() then
					return analysisFailure("Join a chess match first.")
				end
				if not g:isPlayerTurn() then
					return analysisFailure("Wait for your turn.")
				end
				if g:willCauseDesync() then
					return analysisFailure("The board is still updating. Try again shortly.")
				end
				local i = g:getBoard()
				local j = g:readFen()
				if not j or not i then
					return analysisFailure("Could not read the board. Try Refresh board.")
				end
				local k, l, m = f:requestEndpoint("/analyze", {
					fen = j,
					depth = h.depth,
					max_think_time_ms = h.thinkTime,
					disregard_think_time = h.disregardTime,
				})
				if not k then
					return analysisFailure(l, m)
				end
				if g:getBoard() ~= i or not g:isPlayerTurn() or g:readFen() ~= j then
					return analysisFailure(
						"The position changed while the engine was thinking.",
						"stale_position"
					)
				end
				local n, o = d.parseMove(k.best_move)
				if not n then
					return analysisFailure(o)
				end
				local p = g:getBoardPiece(n.fromPos)
				if not p or not g:hasLegalMove(p, n.toPos) then
					return analysisFailure(
						"The engine move is no longer legal. Refresh the board and try again."
					)
				end
				local q = workspace:FindFirstChild("Board")

				local r = q and q:FindFirstChild(table.concat(n.fromPos, ","))
				local s = q and q:FindFirstChild(table.concat(n.toPos, ","))
				if not r or not s then
					return analysisFailure("Could not find the move's tiles in the game.")
				end

				local t
				if type(k.difficulty) == "table" then
					local u = k.difficulty
					if type(u.recommended_delay_ms) == "number" then
						t = { recommended_delay_ms = u.recommended_delay_ms }
					end
				end
				local u = k.best_move
				return {
					success = true,
					best_move = u,
					move = u,
					piece = r,
					destination = s,
					fromPos = n.fromPos,
					toPos = n.toPos,
					promotion = n.promotion,
					fen = j,
					match = i,
					difficulty = t,
				}
			end

			return e
		end
		function a.s()
			local b = a.cache.s
			if not b then
				b = { c = __modImpl() }
				a.cache.s = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			local b = {}

			function b.new()
				local c = Instance.new("Folder")
				c.Name = "ChessMoveHighlights"
				c.Parent = workspace
				return {
					folder = c,
					clear = b.clear,
					show = b.show,
					destroy = b.destroy,
				}
			end

			function b.clear(c)
				c.folder:ClearAllChildren()
			end

			function b.show(c, d, e, f)
				c:clear()
				for g, h in ipairs({ d, e }) do
					local i = Instance.new("Highlight")
					i.Adornee = h
					i.FillColor = f.fillColor
					i.OutlineColor = f.outlineColor
					i.FillTransparency = f.fillTransparency
					i.OutlineTransparency = f.outlineTransparency
					i.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					i.Parent = c.folder
				end
			end

			function b.destroy(c)
				c.folder:Destroy()
			end

			return b
		end
		function a.t()
			local b = a.cache.t
			if not b then
				b = { c = __modImpl() }
				a.cache.t = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			return {}
		end
		function a.u()
			local b = a.cache.u
			if not b then
				b = { c = __modImpl() }
				a.cache.u = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			local b = a.r()
			a.u()

			local c = {}

			local d = 130
			local e = 3
			local f = 0.05
			local g = { q = "Queen", r = "Rook", b = "Bishop", n = "Knight" }

			local function isRequestActive(h, i)
				return not h.destroyed and h.requestVersion == i and (not h.isAlive or h.isAlive())
			end

			local function isPositionCurrent(h, i, j, k)
				return isRequestActive(h, j)
					and (not k or h.options.autoCalculate)
					and h.board:isGameInProgress()
					and h.board:isPlayerTurn()
					and h.board:getBoard() == i.match
					and h.board:readFen() == i.fen
					and not h.board:willCauseDesync()
			end

			local function stopAutomation(h)
				h.options.autoCalculate = false
				if h.onAutomationStopped then
					h.onAutomationStopped()
				end
			end

			local function retryPosition(h)
				h.lastAnalyzedFen = nil
				h.retryAfter = os.clock() + e
			end

			local function executeMove(h, i, j, k)
				local l = b.delayMs(i.difficulty, h.options.useCalculatedDelay, h.options.executeDelay)
				h.emit("status", `Waiting {l} ms before moving…`)
				h.requestPhase = "Waiting before moving…"
				local m = os.clock() + l / 1000
				repeat
					if not isPositionCurrent(h, i, j, k) then
						if isRequestActive(h, j) then
							retryPosition(h)
						end
						return
					end
					if os.clock() >= m then
						break
					end
					task.wait(f)
				until false

				h.requestPhase = "Selecting the piece…"
				local n, o = h.board:autoMove(i.fromPos, i.toPos, i.promotion, function()
					return isPositionCurrent(h, i, j, k)
				end, function()
					return not isRequestActive(h, j)
				end, function()
					if isRequestActive(h, j) then
						h.submittedMove = i
						h.requestPhase = "Waiting for the game to finish the move…"
					end
				end)
				if not isRequestActive(h, j) then
					return
				end
				if n then
					h.emit("status", if i.promotion then "Promotion confirmed" else "Move sent")
					h.emit("output", o)
				elseif i.promotion then
					stopAutomation(h)
					h.emit("status", "Promotion needs attention; Auto Play stopped")
					h.emit("instruction", o)
				else
					retryPosition(h)
					h.emit("status", "Move highlighted")
					h.emit("output", `Best move: {i.move}. {o}`)
				end
			end

			local function analyzePosition(h, i, j, k)
				if not isRequestActive(h, i) then
					return
				end
				local l = h.server:findBestMove(h.board, table.clone(h.options))
				if not isRequestActive(h, i) then
					return
				end
				if not l.success then
					h.emit("output", l.reason)
					h.emit("status", "Needs attention")
					h.retryAfter = os.clock() + e
					return
				end
				if not isPositionCurrent(h, l, i, k) then
					return
				end

				h.highlighter:show(l.piece, l.destination, h.options)
				h.highlightedFen = l.fen
				h.lastAnalyzedFen = l.fen
				h.lastMatch = l.match
				if l.promotion and not j then
					h.emit("status", "Promotion: manual move required")
					h.emit(
						"instruction",
						`Play {l.move} manually and choose {g[l.promotion]}. Auto Play will resume after the position changes.`
					)
					return
				end
				h.emit("output", `Best move: {l.move}`)
				h.emit("status", "Move highlighted")
				if j then
					executeMove(h, l, i, k)
				end
			end

			function c.new(h, i, j, k, l)
				return {
					board = h,
					server = i,
					highlighter = j,
					options = k,
					emit = l,
					busy = false,
					destroyed = false,
					requestVersion = 0,
					retryAfter = 0,
					cancel = c.cancel,
					requestMove = c.requestMove,
					tick = c.tick,
					destroy = c.destroy,
				}
			end

			function c.cancel(h)
				h.requestVersion += 1
				h.busy = false
				h.activeRequest = nil
				h.requestPhase = nil
				h.submittedMove = nil
				h.lastAnalyzedFen = nil
				h.lastMatch = nil
				h.highlightedFen = nil
				h.highlighter:clear()
				if not h.destroyed then
					h.emit("status", "Idle")
				end
			end

			function c.requestMove(h, i, j)
				if h.busy or h.destroyed then
					return false
				end
				h.busy = true
				h.requestVersion += 1
				local k = h.requestVersion
				h.activeRequest = k
				h.requestPhase = "Calculating with Stockfish…"
				h.submittedMove = nil
				h.emit("status", "Calculating…")

				task.delay(d, function()
					if not isRequestActive(h, k) or h.activeRequest ~= k or not h.busy then
						return
					end
					h:cancel()
					h.retryAfter = os.clock() + e
					h.emit("status", "Request timed out")
					h.emit("output", "The server took too long to respond. Check the desktop app and retry.")
				end)
				task.spawn(function()
					local l, m = pcall(function()
						analyzePosition(h, k, i, j)
						return true
					end)
					if not l and isRequestActive(h, k) then
						retryPosition(h)
						h.emit("status", "Needs attention")
						h.emit("output", tostring(m))
					end

					if h.activeRequest == k then
						h.busy = false
						h.activeRequest = nil
						h.requestPhase = nil
						h.submittedMove = nil
					end
				end)
				return true
			end

			function c.tick(h)
				if h.destroyed then
					return
				end
				local i = h.board:isGameInProgress()
				local j = i and h.board:isPlayerTurn()
				local k = if j then h.board:readFen() else nil
				local l = h.board:getBoard()
				local m = h.submittedMove
				if h.busy and m and not m.promotion then
					local n = if i then h.board:readFen() else nil
					if l ~= m.match or (n ~= nil and n ~= m.fen) then
						h.requestVersion += 1
						h.activeRequest = nil
						h.busy = false
						h.submittedMove = nil
						h.requestPhase = nil
						h.emit("status", "Board updated; ready for the next turn")
					end
				end
				if h.highlightedFen and (k ~= h.highlightedFen or l ~= h.lastMatch) then
					h.highlighter:clear()
					h.highlightedFen = nil
				end
				if not j then
					h.lastAnalyzedFen = nil
				end
				local n = if not h.options.autoCalculate
					then "Inactive"
					elseif not i then "Waiting for a match"
					elseif not j then "Waiting for your turn"
					elseif h.busy then h.requestPhase or "Calculating or moving…"
					else "Waiting for your move"
				if n ~= h.automationStatus then
					h.emit("auto", n)
					h.automationStatus = n
				end
				if
					h.options.autoCalculate
					and j
					and k
					and not h.busy
					and os.clock() >= h.retryAfter
					and (k ~= h.lastAnalyzedFen or l ~= h.lastMatch)
				then
					h:requestMove(h.options.autoExecute, true)
				end
			end

			function c.destroy(h)
				h.destroyed = true
				h.requestVersion += 1
				h.highlighter:destroy()
			end

			return c
		end
		function a.v()
			local b = a.cache.v
			if not b then
				b = { c = __modImpl() }
				a.cache.v = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.o()

			local b = {}

			function b.defaults()
				return {
					depth = 17,
					thinkTime = 100,
					disregardTime = false,
					autoCalculate = false,
					autoExecute = false,
					executeDelay = 300,
					useCalculatedDelay = false,
					fillColor = Color3.fromRGB(59, 235, 223),
					outlineColor = Color3.fromRGB(255, 255, 255),
					fillTransparency = 0.5,
					outlineTransparency = 0,
				}
			end

			return b
		end
		function a.w()
			local b = a.cache.w
			if not b then
				b = { c = __modImpl() }
				a.cache.w = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = a.q()
			local c = a.s()
			local d = a.t()
			local e = a.v()
			local f = a.w()
			local g = a.b()
			local h = a.m()
			a.e()
			a.o()
			a.c()

			local i = "https://github.com/keplerHaloxx/roblox-chess-script/releases/latest"

			local function copyServerReleaseLink(j)
				local k = j.window
				local l = pcall(function()
					g.setclipboard(i)
				end)
				if l then
					j:notify(
						"Release link copied",
						"Paste it into your browser to download the latest server."
					)
				else
					k:Popup({
						title = "Open the release page",
						content = "Your executor could not copy the link. Open this address:\n" .. i,
						options = { { text = "Dismiss" } },
					})
				end
			end

			local function formatMoveMessage(j)
				return string.gsub(j, "Best move: ([a-h][1-8])([a-h][1-8])", "%1 → %2", 1)
			end

			local function readEngineStatus(j)
				local k = j.engine
				if type(k) ~= "table" then
					return "unknown"
				end
				return tostring((k).status or "unknown")
			end

			return function(j)
				local k = j.window

				local l = f.defaults()
				local m = false
				local n = false

				local o
				local p
				local q
				local r
				local s
				local t

				local u = b.new()
				local v = c.new(g.request)
				local w
				local x = d.new()
				j:trackCleanup(function()
					if w then
						w:destroy()
					else
						x:destroy()
					end
				end)

				local function clearOutput()
					if p then
						p:Set("No move selected. Choose Suggest move to analyze the board.")
					end
				end

				local function stopChess()
					if not j.alive then
						return true
					end
					l.autoCalculate = false
					l.autoExecute = false
					if s then
						s:Set(false, true)
					end
					if t then
						t:Set(false, true)
					end
					if w then
						w:cancel()
					end
					clearOutput()
					return true
				end

				local function report(y, z)
					if not j.alive or k.unloaded then
						return
					end
					if y == "auto" then
						if q then
							q:Set(if z == "Inactive" then "Off · Enable Auto calculate to begin" else z)
						end
					elseif y == "status" then
						if o then
							o:Set(if z == "Idle" then "Ready when you are" else z)
						end
					else
						if z == "Move attempted" then
							return
						end
						if p then
							p:Set(formatMoveMessage(z))
						end
					end
				end
				local y = e.new(u, v, x, l, report)
				w = y
				y.isAlive = function()
					return j.alive and not k.unloaded
				end

				local function requestMove(z)
					if not j.alive or k.unloaded then
						return
					end
					if not y:requestMove(z, false) then
						j:notify("Already working", "Wait for the current request or cancel it first.")
					end
				end

				local function reconnectBoard()
					if not j.alive or k.unloaded then
						return
					end
					y:cancel()
					local z = u:refreshClient()
					if z then
						report("output", "Board client found.")
					else
						report("output", "Board client not found. Check executor support and join a match.")
					end
				end

				local function checkServerConnection()
					local z = r
					if n or not j.alive or not z then
						return
					end
					n = true
					z:Set("Checking the desktop server…")
					local A
					local B
					local C, D = pcall(function()
						A, B = v:requestEndpoint("/status")
						return true
					end)

					n = false
					if not j.alive or k.unloaded then
						return
					end
					if not C then
						A = nil
						B = tostring(D)
					end
					local E = if A then readEngineStatus(A) else "unknown"

					if not A then
						z:Set("Offline · Open the desktop app and try again.")
						j:notify("Connection failed", B or "The server did not respond.")
					elseif E == "ready" then
						z:Set("Connected · Stockfish is ready")
						j:notify("Server connected", "Stockfish is ready.")
					else
						z:Set("Connected · Engine: " .. E)
						j:notify("Server connected", "Engine: " .. E)
					end
				end

				local function showServerCompatibilityWarning(z)
					if m or not j.alive or k.unloaded then
						return
					end
					m = true
					k:Popup({
						title = "Server update required",
						content = z,
						options = {
							{ text = "Dismiss" },
							{
								text = "Copy release link",
								callback = function()
									copyServerReleaseLink(j)
								end,
							},
						},
					})
				end
				v.onIncompatible = showServerCompatibilityWarning

				y.onAutomationStopped = function()
					if s then
						s:Set(false, true)
					end
				end

				local z = k:CreateTab({ name = "Chess", icon = "sparkles" })
				local A = k:CreateTab({ name = "Auto Play", icon = "play" })
				local B = k:CreateTab({ name = "Engine", icon = "sliders-horizontal" })

				o = z:CreateText({ name = "Status", text = "Ready when you are" })
				p = z:CreateText({
					name = "Suggested move",
					text = "Join a match, then choose Suggest move below.",
				})
				q = A:CreateText({ name = "Auto Play", text = "Off · Enable Auto calculate to begin" })

				z:CreateSection({ name = "Your next move" })
				local C = z:CreateGroup({ direction = "row" })
				C:CreateButton({
					name = "Suggest move",
					icon = "sparkles",
					callback = function()
						requestMove(false)
					end,
				})
				C:CreateButton({
					name = "Play best move",
					icon = "play",
					callback = function()
						requestMove(true)
					end,
				})
				z:CreateButton({
					name = "Stop & clear",
					icon = "square",
					description = "Cancel pending moves, stop Auto Play, and clear highlights.",
					callback = stopChess,
				})
				z:CreateText({
					name = "How to play",
					text = "Suggest move marks the two squares. Play best move calculates and clicks for you. Open Auto Play to repeat this on every turn.",
				})
				z:CreateSection({ name = "Connection" })
				r = z:CreateText({
					name = "Desktop server",
					text = "Not checked. Open the desktop app, then check the connection.",
				})

				z:CreateButton({
					name = "Check connection",
					icon = "check",
					callback = checkServerConnection,
				})
				B:CreateSection({ name = "Search strength" })
				B:CreateSlider({
					name = "Search depth",
					description = "Higher depth searches further when time allows.",
					range = { 1, 40 },
					increment = 1,
					value = l.depth,
					flag = "Chess_Depth",
					callback = function(D)
						l.depth = D
					end,
				})
				B:CreateSlider({
					name = "Time per suggestion",
					range = { 10, 5000 },
					increment = 10,
					suffix = "ms",
					value = l.thinkTime,
					flag = "Chess_MaxThinkTime",
					callback = function(D)
						l.thinkTime = D
					end,
				})
				B:CreateToggle({
					name = "Search until depth is reached",
					description = "Ignore the time limit. Deep searches can take longer.",
					value = l.disregardTime,
					flag = "Chess_DisregardThinkTime",
					callback = function(D)
						l.disregardTime = D
					end,
				})

				B:CreateSection({ name = "Troubleshooting" })
				B:CreateButton({
					name = "Reconnect to board",
					icon = "activity",
					description = "Try this if the board cannot be read after joining a match.",
					callback = reconnectBoard,
				})

				A:CreateSection({ name = "Automation" })
				s = A:CreateToggle({
					name = "Auto calculate",
					flag = "Chess_AutoCalculate",
					value = l.autoCalculate,
					description = "Keep suggestions up to date whenever your turn begins. Does not move pieces on its own.",
					callback = function(D)
						l.autoCalculate = D
						y:cancel()
					end,
				})
				t = A:CreateToggle({
					name = "Auto execute move",
					flag = "Chess_AutoExecute",
					value = l.autoExecute,
					description = "Play suggestions automatically when Auto calculate is on.",
					callback = function(D)
						l.autoExecute = D
						y:cancel()
					end,
				})

				A:CreateSection({ name = "Timing" })
				A:CreateSlider({
					name = "Pause before moving",
					range = { 0, 3000 },
					increment = 50,
					suffix = "ms",
					value = l.executeDelay,
					flag = "Chess_ExecuteDelay",
					callback = function(D)
						l.executeDelay = D
					end,
				})
				A:CreateToggle({
					name = "Use suggested pause",
					flag = "Chess_UseCalculatedDelay",
					value = l.useCalculatedDelay,
					description = "Use the server's timing when available; otherwise use the pause above. (VERY experimental, don't recommend)",
					callback = function(D)
						l.useCalculatedDelay = D
					end,
				})

				B:CreateSection({ name = "Highlight colors" })
				B:CreateColorPicker({
					name = "Highlight fill",
					color = l.fillColor,
					alpha = 1 - l.fillTransparency,
					flag = "Chess_HighlightFillColor",
					callback = function(D, E)
						l.fillColor = D
						l.fillTransparency = 1 - E
					end,
				})
				B:CreateColorPicker({
					name = "Highlight outline",
					color = l.outlineColor,
					alpha = 1 - l.outlineTransparency,
					flag = "Chess_HighlightOutlineColor",
					callback = function(D, E)
						l.outlineColor = D
						l.outlineTransparency = 1 - E
					end,
				})

				local D = 0
				local E = false
				j:trackConnection(h("RunService").Heartbeat:Connect(function()
					if not j.alive or E or os.clock() < D then
						return
					end
					E = true
					D = os.clock() + 0.2
					local F, G = pcall(function()
						y:tick()
					end)
					E = false
					if not F and j.alive then
						D = os.clock() + 3
						report("status", "Waiting for the board to update")
						report("output", "Board read failed; retrying shortly. " .. tostring(G))
					end
				end))

				return {
					tab = z,
					stop = stopChess,
					testingProps = {
						controller = y,
					},
				}
			end
		end
		function a.x()
			local b = a.cache.x
			if not b then
				b = { c = __modImpl() }
				a.cache.x = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.e()

			local b = {
				{
					name = "Example",
					placeIds = {},
					start = function(b)
						return a.f()(b)
					end,
				},
				{
					name = "RoBeats",
					placeIds = { 698448212 },
					start = function(b)
						return a.n()(b)
					end,
				},
				{
					name = "Chess",
					placeIds = { 6222531507 },
					start = function(b)
						return a.x()(b)
					end,
				},
			}

			return b
		end
		function a.y()
			local b = a.cache.y
			if not b then
				b = { c = __modImpl() }
				a.cache.y = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.e()
			a.c()

			local b = a.b()

			local c = {}

			local function releaseResources(d)
				local e = {}
				for f = #d, 1, -1 do
					local g, h = pcall(function()
						d[f]()
						return true
					end)
					if g then
						table.remove(d, f)
					else
						table.insert(e, tostring(h))
					end
				end
				return if #e > 0 then table.concat(e, "\n") else nil
			end

			function c.create(d)
				local e = { window = d, alive = true }
				local f = {}
				local g = {}
				local h = d.Unload
				local i = false
				local j = false
				local k = false

				local function cleanupResources()
					local l = releaseResources(f)
					local m = releaseResources(g)
					if l and m then
						return l .. "\n" .. m
					end
					return l or m
				end

				function e.trackCleanup(l, m, ...)
					assert(l.alive and not j, "Cannot register cleanup after unloading has started")
					local n = table.pack(...)

					local o = m
					table.insert(g, function()
						o(table.unpack(n, 1, n.n))
					end)
				end

				function e.trackConnection(l, m)
					if not l.alive or j then
						m:Disconnect()
						error("Cannot register a connection after unloading has started")
					end
					table.insert(f, function()
						m:Disconnect()
					end)
					return m
				end

				function e.trackInstance(l, m)
					local n = m
					if not l.alive or j then
						n:Destroy()
						error("Cannot register an instance after unloading has started")
					end
					l:trackCleanup(n.Destroy, n)
					return m
				end

				function e.notify(l, m, n, o, p)
					if not i and not l.window.unloaded then
						l.window:Notify({ title = m, content = n, duration = p or 6, icon = o })
					end
				end

				function e.loadGame(l, m)
					assert(
						l.alive and not k and not l.game,
						"A game is already loaded or the hub is stopping"
					)
					k = true
					local n, o = pcall(m, l)
					k = false
					if not n then
						l.alive = false
						j = true
						local p = cleanupResources()
						j = false
						l.alive = p == nil and not i
						error(tostring(o) .. (if p then "\nCleanup needs retry: " .. p else ""), 0)
					end

					assert(l.alive and not i, "Game initialization was interrupted by unload")
					l.game = o
				end

				function e.stop(l)
					if l.alive and l.game and l.game.stop then
						assert(l.game.stop() ~= false, "Could not stop game input")
					end
				end

				function e.unload(l)
					if i or j then
						return
					end
					j = true
					l.alive = false
					local m = cleanupResources()
					if not m then
						local n, o = pcall(function()
							h(l.window)
							return true
						end)
						if not n then
							m = tostring(o)
						end
					end
					j = false
					if m then
						error(m, 0)
					end
					i = true
					if b.getgenv().Kepler == l then
						b.getgenv().Kepler = nil
					end
				end

				d.Unload = function()
					e:unload()
				end
				return e
			end

			return c
		end
		function a.z()
			local b = a.cache.z
			if not b then
				b = { c = __modImpl() }
				a.cache.z = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			a.e()
			a.c()

			local b = {}

			function b.create(c)
				local d = c.window:CreateTab({ name = "Hub", icon = "moon" })
				d:CreateDropdown({
					name = "Theme",
					options = { "Default", "Cobalt", "Ember", "Amethyst", "Frost", "Rose" },
					value = "Amethyst",
					flag = "Hub_Theme",
					callback = function(e)
						c.window:ChangeTheme((string.lower(e)))
					end,
				})

				local e = d:CreateGroup({ direction = "row" })
				local function run(f)
					local g, h = pcall(f)
					if not g then
						c:notify("Cleanup needs retry", h)
					end
				end

				e:CreateButton({
					name = "Stop all",
					icon = "square",
					callback = function()
						run(function()
							c:stop()
						end)
					end,
				})

				e:CreateButton({
					name = "Unload",
					icon = "power",
					callback = function()
						run(function()
							c:unload()
						end)
					end,
				})

				return d
			end

			return b
		end
		function a.A()
			local b = a.cache.A
			if not b then
				b = { c = __modImpl() }
				a.cache.A = b
			end
			return b.c
		end
	end
	do
		local function __modImpl()
			local b = {}

			local c = {
				moon = { 16898613613, 306, 918 },
				["music-2"] = { 16898613613, 404, 869 },
				play = { 16898613699, 918, 257 },
				activity = { 16898612629, 514, 771 },
				sparkles = { 16898613777, 918, 49 },
				check = { 16898612819, 710, 869 },
				circle = { 16898613044, 771, 355 },
				x = { 16898613869, 869, 906 },
				["sliders-horizontal"] = { 16898613777, 820, 355 },
				["bar-chart-3"] = { 16898612629, 918, 759 },
				square = { 16898613777, 869, 710 },
				power = { 16898613699, 820, 147 },
			}

			local function resolve(d)
				local e = d and c[d.Image]
				if d and e then
					d.Image = "rbxassetid://" .. e[1]
					d.ImageRectSize = Vector2.new(48, 48)
					d.ImageRectOffset = Vector2.new(e[2], e[3])
				end
			end

			function b.attach(d)
				if not d.Create then
					return
				end
				if d.topbarIcon then
					local e = { Image = d.topbarIcon.Image }
					resolve(e)
					for f, g in pairs(e) do
						d.topbarIcon[f] = g
					end
				end
				local e = d.Create
				d.Create = function(f, g, h, i)
					if g == "ImageLabel" or g == "ImageButton" then
						resolve(h)
					end
					return e(f, g, h, i)
				end
			end

			return b
		end
		function a.B()
			local b = a.cache.B
			if not b then
				b = { c = __modImpl() }
				a.cache.B = b
			end
			return b.c
		end
	end
end

local b = a.b()
a.c()

local c = a.d()
local d = a.y()
local e = a.z()
local f = a.A()
local g = a.B()

local h = b.getgenv()
if h.Kepler then
	h.Kepler:unload()
end

local i
for j, k in d do
	if table.find(k.placeIds, game.PlaceId) then
		i = k
		break
	end
end

local j = c
local k = j:CreateWindow({
	name = "Kepler",
	subtitle = i and i.name or "Game hub",
	icon = "moon",
	theme = "amethyst",
	sidebarLayout = false,
	configuration = {
		autoSave = true,
		autoLoad = true,
		customFolder = "KeplerConfig",
		fileName = "Kepler-" .. tostring(game.PlaceId),
	},
})

g.attach(k)

local l = e.create(k)
h.Kepler = l

if i then
	local m, n = pcall(function()
		l:loadGame(i.start)
	end)
	if not m then
		l:notify("Game module could not start", tostring(n))
	end
end

local m = f.create(l)

if l.game and l.game.tab then
	l.game.tab:Select(true)
else
	m:Select(true)
end

return l