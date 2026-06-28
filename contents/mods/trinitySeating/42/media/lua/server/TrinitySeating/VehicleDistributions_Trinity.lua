require "Vehicles/VehicleDistributions"

for _, distribution in pairs(VehicleDistributions) do
    if type(distribution) == "table" and (distribution.SeatFrontLeft or distribution.SeatFrontRight) and not distribution.SeatFrontMiddle then
        distribution.SeatFrontMiddle = distribution.SeatFrontRight or VehicleDistributions.Seat
    end
end
