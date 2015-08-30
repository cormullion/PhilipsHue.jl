using Compat
using PhilipsHue

println("loaded PhilipsHue, Compat")

# these will have to be set to valid values before you run the test

B = PhilipsHueBridge("192.168.1.119", "juliauser1")
println("Bridge config: \t"   , getbridgeconfig(B))

println("Bridge IP: \t"       , getIP())
println("Bridge initialized?: \t"       , initialized?())
println("Light config: \t"    , getlights(B))
println("Get light config: \t", getlight(B))
println("Get light config: \t", getlight(B, 4))
println("Set light 1 on: \t"  , setlight(B, 1, @compat Dict("on" => true)))
println("Set light 1 off: \t" , setlight(B, 1, @compat Dict("on" => false)))
println("Set light 1 \t"      , setlight(B, 1, @compat Dict("on" => true, "sat" => 123, "bri" => 243, "hue" => 123)))

for i in 0:20
    setlights(B, @compat Dict("bri" => rand(0:255), "hue" => rand(1:65000), "sat" => rand(1:255)))
    sleep(0.5)
end

setlights(B, @compat Dict("bri" => 255))
