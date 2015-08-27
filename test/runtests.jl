tic()
using Base.Test, Compat, using PhilipsHue

println("loaded PhilipsHue, Test, Compat")

B = PhilipsHueBridge("192.168.1.90", "username")
println(getbridgeconfig(B))
println(getIP())
println(getlights(B))
println(getlight(B))
println(getlight(B, 4))
println(setlight(B, 1, @compat Dict{Any,Any}("on" => true)))
println(setlight(B, 1, @compat Dict{Any,Any}("on" => false)))
println(setlight(B, 1, @compat Dict{Any,Any}("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)))

for i in 0:10
    setlights(B, @compat Dict{Any,Any}("bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255)))
    sleep(0.5)
end

setlights(B, @compat Dict{Any,Any}("bri" => 255))

toc()
