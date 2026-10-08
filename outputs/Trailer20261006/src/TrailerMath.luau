-- TrailerMath (2026-10-06, Claude): pure math for the page-trailer director (DESIGN rev 2, sections 5.2, 6, 7.3, 11).
-- Easing, centripetal Catmull-Rom, exponential smoothing, angle helpers, pure pursuit and the speed-profile solvers that the
-- real-plow driver and the puppets share. No instances, no services, no side effects: Edit can require it and run SelfTest().
local M = {}

local PI = math.pi

function M.clamp(x, a, b)
	if x < a then return a elseif x > b then return b end
	return x
end
function M.lerp(a, b, t) return a + (b - a) * t end -- numbers and Vector3 alike
function M.flat(v) return Vector3.new(v.X, 0, v.Z) end
function M.flatUnit(v, fallback)
	local f = Vector3.new(v.X, 0, v.Z)
	if f.Magnitude < 1e-4 then return fallback or Vector3.new(0, 0, -1) end
	return f.Unit
end
function M.finite(x) return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge end
function M.finiteV(v) return typeof(v) == "Vector3" and M.finite(v.X) and M.finite(v.Y) and M.finite(v.Z) end

--------------------------------------------------------------------------------------------------------------------------------
-- easing (u in 0..1)
--------------------------------------------------------------------------------------------------------------------------------
M.Ease = {
	Linear = function(u) return u end,
	InQuad = function(u) return u * u end,
	OutQuad = function(u) return 1 - (1 - u) * (1 - u) end,
	InOutQuad = function(u) if u < 0.5 then return 2 * u * u end return 1 - (-2 * u + 2) ^ 2 / 2 end,
	InSine = function(u) return 1 - math.cos(u * PI / 2) end,
	OutSine = function(u) return math.sin(u * PI / 2) end,
	InOutSine = function(u) return -(math.cos(PI * u) - 1) / 2 end,
	OutCubic = function(u) return 1 - (1 - u) ^ 3 end,
	BackOut = function(u) local c1 = 1.70158; local c3 = c1 + 1; return 1 + c3 * (u - 1) ^ 3 + c1 * (u - 1) ^ 2 end,
}
function M.ease(name, u)
	local f = M.Ease[name or "Linear"] or M.Ease.Linear
	return f(M.clamp(u, 0, 1))
end

--------------------------------------------------------------------------------------------------------------------------------
-- angles and smoothing
--------------------------------------------------------------------------------------------------------------------------------
function M.wrap(a) return (a + PI) % (2 * PI) - PI end
-- yaw such that CFrame.Angles(0, yaw, 0).LookVector points along look (flat)
function M.yawOf(look) return math.atan2(-look.X, -look.Z) end
function M.alpha(dt, tau)
	if not tau or tau <= 0 then return 1 end
	return 1 - math.exp(-dt / tau)
end
function M.smooth(cur, target, dt, tau) return cur + (target - cur) * M.alpha(dt, tau) end
function M.smoothAngle(cur, target, dt, tau) return cur + M.wrap(target - cur) * M.alpha(dt, tau) end
-- signed angle from a flat forward vector to a flat direction (positive = to the right, like PlowDriveClient's AFK steer)
function M.angleTo(look, dir)
	local right = Vector3.new(-look.Z, 0, look.X)
	return math.atan2(dir:Dot(right), dir:Dot(look))
end
-- orbit offset: degrees, 0 = +X, 90 = +Z
function M.orbitOffset(deg, radius)
	local a = math.rad(deg)
	return Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
end

--------------------------------------------------------------------------------------------------------------------------------
-- centripetal Catmull-Rom (Barry-Goldman), alpha 0.5
--------------------------------------------------------------------------------------------------------------------------------
local function knot(ti, a, b, alpha)
	return ti + math.max((b - a).Magnitude, 1e-4) ^ alpha
end
function M.catmullRom(p0, p1, p2, p3, s, alpha)
	alpha = alpha or 0.5
	local t0 = 0
	local t1 = knot(t0, p0, p1, alpha)
	local t2 = knot(t1, p1, p2, alpha)
	local t3 = knot(t2, p2, p3, alpha)
	local t = t1 + (t2 - t1) * s
	local a1 = p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0))
	local a2 = p1 * ((t2 - t) / (t2 - t1)) + p2 * ((t - t1) / (t2 - t1))
	local a3 = p2 * ((t3 - t) / (t3 - t2)) + p3 * ((t - t2) / (t3 - t2))
	local b1 = a1 * ((t2 - t) / (t2 - t0)) + a2 * ((t - t0) / (t2 - t0))
	local b2 = a2 * ((t3 - t) / (t3 - t1)) + a3 * ((t - t1) / (t3 - t1))
	return b1 * ((t2 - t) / (t2 - t1)) + b2 * ((t - t1) / (t2 - t1))
end
-- points: Vector3 list, times: ascending normalised key times (same length); u: 0..1. Ends are mirrored (no overshoot).
function M.spline(points, times, u)
	local n = #points
	if n == 0 then return nil end
	if n == 1 or u <= times[1] then return points[1] end
	if u >= times[n] then return points[n] end
	local i = 1
	while i < n - 1 and u > times[i + 1] do i += 1 end
	local span = times[i + 1] - times[i]
	local s = span > 1e-6 and (u - times[i]) / span or 0
	local p1, p2 = points[i], points[i + 1]
	local p0 = points[i - 1] or (p1 * 2 - p2)
	local p3 = points[i + 2] or (p2 * 2 - p1)
	return M.catmullRom(p0, p1, p2, p3, s, 0.5)
end
-- piecewise-linear numbers (FOV, roll)
function M.linear(values, times, u)
	local n = #values
	if n == 0 then return nil end
	if n == 1 or u <= times[1] then return values[1] end
	if u >= times[n] then return values[n] end
	local i = 1
	while i < n - 1 and u > times[i + 1] do i += 1 end
	local span = times[i + 1] - times[i]
	return M.lerp(values[i], values[i + 1], span > 1e-6 and (u - times[i]) / span or 0)
end

--------------------------------------------------------------------------------------------------------------------------------
-- pure pursuit on a flat polyline
--------------------------------------------------------------------------------------------------------------------------------
-- returns: lookahead target (Vector3), distance left along the path from the projection, segment index, projection point
function M.pursuit(path, pos, lookahead, hint)
	local n = #path
	if n == 0 then return pos, 0, 1, pos end
	if n == 1 then return path[1], M.flat(path[1] - pos).Magnitude, 1, path[1] end
	local p = M.flat(pos)
	local bestI, bestD, bestS = math.max(1, hint or 1), math.huge, 0
	for i = math.max(1, (hint or 1) - 1), n - 1 do
		local a, b = M.flat(path[i]), M.flat(path[i + 1])
		local ab = b - a
		local len2 = ab:Dot(ab)
		local s = len2 > 1e-6 and M.clamp((p - a):Dot(ab) / len2, 0, 1) or 0
		local d = (a + ab * s - p).Magnitude
		if d < bestD - 1e-6 then bestI, bestD, bestS = i, d, s end
	end
	local a, b = path[bestI], path[bestI + 1]
	local proj = a + (b - a) * bestS
	-- distance left
	local left = M.flat(b - proj).Magnitude
	for i = bestI + 1, n - 1 do left += M.flat(path[i + 1] - path[i]).Magnitude end
	-- walk the lookahead
	local need, i, from = lookahead, bestI, proj
	while true do
		local to = path[i + 1]
		local seg = M.flat(to - from).Magnitude
		if seg >= need or i >= n - 1 then
			if seg < 1e-6 then return to, left, bestI, proj end
			return from + (to - from) * math.min(1, need / seg), left, bestI, proj
		end
		need -= seg
		i += 1
		from = path[i]
	end
end
function M.pathLength(path)
	local L = 0
	for i = 1, #path - 1 do L += M.flat(path[i + 1] - path[i]).Magnitude end
	return L
end

--------------------------------------------------------------------------------------------------------------------------------
-- speed profiles (a = acceleration, b = braking, both studs/s^2, vmax studs/s)
--------------------------------------------------------------------------------------------------------------------------------
-- rest-to-rest: the smallest cruise speed that covers D in exactly T; nil if even vmax cannot
function M.timedCruise(D, T, a, b, vmax)
	if D <= 0 then return 0 end
	if T <= 0 then return nil end
	local k = 1 / (2 * a) + 1 / (2 * b)
	local disc = T * T - 4 * k * D
	if disc < 0 then return nil end
	local v = (T - math.sqrt(disc)) / (2 * k)
	if v > vmax + 1e-6 then return nil end
	return v
end
-- rest-to-rest minimum time
function M.minTime(D, a, b, vmax)
	if D <= 0 then return 0 end
	local k = 1 / (2 * a) + 1 / (2 * b)
	if D <= k * vmax * vmax then
		local v = math.sqrt(D / k)
		return v / a + v / b
	end
	return vmax / a + vmax / b + (D - k * vmax * vmax) / vmax
end
-- from rest, passing the point at speed (no stop)
function M.timeFromRest(D, a, vmax)
	if D <= 0 then return 0 end
	local dAcc = vmax * vmax / (2 * a)
	if D <= dAcc then return math.sqrt(2 * D / a) end
	return vmax / a + (D - dAcc) / vmax
end
-- puppet "enter at cruise, brake to a stop": cruise v so that D is covered in T ending at rest; nil if T is too short
function M.cruiseThenBrake(D, T, b)
	local disc = b * b * T * T - 2 * b * D
	if disc < 0 then return nil end
	return b * T - math.sqrt(disc)
end

--------------------------------------------------------------------------------------------------------------------------------
-- self test (Edit compile/data check, DESIGN 14.2)
--------------------------------------------------------------------------------------------------------------------------------
function M.SelfTest()
	local errs = {}
	local function check(ok, msg) if not ok then table.insert(errs, msg) end end
	local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-3) end
	for name, f in pairs(M.Ease) do
		check(near(f(0), 0) and near(f(1), 1), "ease " .. name .. " endpoints")
	end
	check(near(M.wrap(3 * PI), PI) or near(M.wrap(3 * PI), -PI), "wrap 3pi")
	check(near(M.wrap(0.5), 0.5), "wrap small")
	local look = CFrame.Angles(0, M.yawOf(Vector3.new(1, 0, 0)), 0).LookVector
	check(near(look.X, 1) and near(look.Z, 0), "yawOf +X")
	check(M.angleTo(Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) > 0, "angleTo right is positive")
	local p = {Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), Vector3.new(20, 5, 0)}
	local t = {0, 0.5, 1}
	check((M.spline(p, t, 0.5) - p[2]).Magnitude < 1e-3, "spline passes its knots")
	check((M.spline(p, t, 0) - p[1]).Magnitude < 1e-3 and (M.spline(p, t, 1) - p[3]).Magnitude < 1e-3, "spline ends")
	local mid = M.spline({Vector3.new(0, 0, 0), Vector3.new(10, 0, 0)}, {0, 1}, 0.5)
	check((mid - Vector3.new(5, 0, 0)).Magnitude < 1e-3, "two keys = straight line")
	check(near(M.linear({60, 40}, {0, 1}, 0.25), 55), "linear fov")
	local v = M.timedCruise(34, 2, 40, 90, 41)
	check(v ~= nil and near(v * 2 - v * v * (1 / 80 + 1 / 180), 34, 1e-2), "timedCruise covers D")
	check(M.timedCruise(34, 1.0, 40, 90, 41) == nil, "timedCruise infeasible")
	local tm = M.minTime(34, 40, 90, 41)
	check(M.timedCruise(34, tm + 1e-3, 40, 90, 41) ~= nil, "minTime consistent")
	check(near(M.timeFromRest(20, 40, 100), 1), "timeFromRest")
	local vc = M.cruiseThenBrake(19.4, 1.6, 72)
	check(vc ~= nil and near(vc * 1.6 - vc * vc / (2 * 72), 19.4, 1e-2), "cruiseThenBrake")
	local tgt, left = M.pursuit({Vector3.new(0, 0, 0), Vector3.new(0, 0, -100)}, Vector3.new(1, 0, -10), 8, 1)
	check(near(tgt.Z, -18, 1e-2) and near(left, 90, 1e-2), "pursuit straight line")
	return #errs == 0, errs
end

return M
