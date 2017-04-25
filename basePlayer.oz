functor
import
   Input
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream

   %variables map
   EMPTY=0
   LAND=1
   VISITED=2
   MINE=3


   
   /*fun {SetVal Map X Y Val}
	fun {Row Map X}
	   if Map == nil then skip
	   elseif X == 1 then {Column Map.1 Y Val}
	   else {Row Map.2 X-1}
	   end
	end
      
	fun {Column Map Y Val}
	   if Map == nil then skip
	   elseif Y == 1 then Map.1 = Val
	   else {Column Map.2 Y-1 Val}
	   end
	end
     end
   
   fun {ClearMap}
      fun {Clear Map ToClear}
	 case ToClear of
	    nil then skip
	 [] H|T then {SetVal Map H.x H.y 0} andthen {Clear CurrentMap T}
	 in
	    {Clear CurrentMap Path}
	 end
      end

      fun {SetVisited Map X Y}
	 {SetVal Map X Y 2}
      end
   end
   */
   
   
   fun{InitPosition ID Position}
      X Y Map NRow NCol in
      Map = Input.Map
      NRow = Input.NRow
      NCol = Input.NColumn
      
      X = 1 + ({Abs{Os.rand}} mod NRow)
      Y = 1 + ({Abs{Os.rand}} mod NCol)

      if {Nth {Nth Map X} Y}==EMPTY then
	 Position = pt(x:X y:Y)
	 Position
      else {InitPosition ID Position}end
   end

   fun{NotOnPath X Y Path}
      case Path of nil then true
      []H|T then if H.x==X then false
		    elseif H.y==Y then false
		 else {NotOnPath X Y T}end
      end
   end

   fun{Move ID Position Direction Path Surface}
      Dir Map X Y in
      Map = Input.Map
      X = Path.1.x
      Y = Path.1.y
      Dir = {Os.rand} +1 mod 50
      if Dir == 0 then Position = Path.1
	 Direction = surface
	 Surface = true
	 nil
      else Dir = {Abs{Os.rand}} mod 4
	 case Dir of
	    0 then if {Nth {Nth Map X+1} Y}==EMPTY andthen {NotOnPath X+1 Y Path}
		   then Position = pt(x:X+1 y:Y)
		      Direction = south
		      Position|Path
		   else {Move ID Position Direction Path} end
	   []1 then if {Nth {Nth Map X-1} Y}==EMPTY andthen {NotOnPath X-1 Y Path}
		   then Position = pt(x:X-1 y:Y)
		      Direction = north
		      Position|Path
		   else {Move ID Position Direction Path} end
	   []2 then if {Nth {Nth Map X} Y-1}==EMPTY andthen {NotOnPath X Y-1 Path}
		   then Position = pt(x:X y:Y-1)
		      Direction = west
		      Position|Path
		   else {Move ID Position Direction Path} end
	   []3 then if {Nth {Nth Map X} Y+1}==EMPTY andthen {NotOnPath X Y+1 Path}
		   then Position = pt(x:X y:Y+1)
		      Direction = east
		      Position|Path
		   else {Move ID Position Direction Path} end
	 end

      end
   end
      

   fun{ChargeItem ID KindItem Items}
      Rnd in
      Rnd = {Abs{Os.rand}} mod 4
      case Rnd of
	 0 then items(mine:Items.mine+1 sonar:Items.sonar drone:Items.drone missile:Items.missile placedmines:Items.placedmines)
	 if Items.mine + 1 mod Input.Mine == 0 then KindItem = mine
	 else KindItem = null end
      []1 then items(mine:Items.mine sonar:Items.sonar+1 drone:Items.drone missile:Items.missile placedmines:Items.placedmines)
	 if Items.sonar + 1 mod Input.Sonar == 0 then KindItem = sonar
	 else KindItem = null end
      []2 then items(mine:Items.mine sonar:Items.sonar drone:Items.drone+1 missile:Items.missile placedmines:Items.placedmines)
	 if Items.drone + 1 mod Input.Drone == 0 then KindItem = drone
	 else KindItem = null end
      []3 then items(mine:Items.mine sonar:Items.sonar drone:Items.drone missile:Items.missile+1 placedmines:Items.placedmines)
	 if Items.missile + 1 mod Input.Missile == 0 then KindItem = missile
	 else KindItem = null end	  
      end
   end

fun {CoordMine X Y Map}
      MineX MineY NRow NCol PosMine in
      NRow = Input.NRow
      NCol = Input.NColumn
      
      MineX = 1 + ({Abs{Os.rand}} mod NRow)
      MineY = 1 + ({Abs{Os.rand}} mod NCol)

      if {Nth {Nth Map MineX} MineY}==EMPTY && {Abs MineX - X} > MaxDistanceMine && {Abs MineY - Y} > MaxDistanceMine then
	 PosMine = pt(x:MineX y:MineY)
	 mine(PosMine)
      else {CoordMine X Y Map}end
   end

   fun {CoordMissile X Y Map}
      MissileX MissileY NRow NCol PosMissile in
      NRow = Input.NRow
      NCol = Input.NColumn
      
      MissileX = 1 + ({Abs{Os.rand}} mod NRow)
      MissileY = 1 + ({Abs{Os.rand}} mod NCol)

      if {Nth {Nth Map MissileX} MissileY}==EMPTY && {Abs MissileX - X} > MaxDistanceMissile && {Abs MissileY - Y} > MaxDistanceMissile then
	 PosMissile = pt(x:MissileX y:MissileY)
	 missile(PosMissile)
      else {CoordMissile X Y Map}end
   end

   fun {CoordDrone}
      DroneX DroneY NRow NCol in

      Rnd = {Abs{Os.rand}} mod 2

      if Rnd = 0 then NRow = Input.NRow
	 DroneX = 1 + ({Abs{Os.rand}} mod NRow)
	 drone(row DroneX)
      else NCol = Input.NColumn
	 DroneY = 1 + ({Abs{Os.rand}} mod NCol)
	 drone(column DroneY)
      end
   end

   %dans treatStream Map = Input.Map
   fun{FireItem ID KindFire Items Position Map}
      Rnd in
      Rnd = {Abs{Os.rand}} mod 4
      if Rnd == 0 && Items.mine > Input.Mine then KindFire = {CoordMine Position.x Position.y Map}
	 items(mine:Items.mine-Input.Mine sonar:Items.sonar drone:Items.drone missile:Items.missile placedmines:KindFire.position|Items.placedmines)
      elseif Rnd == 3 && Items.missile > Input.Missile then KindFire = {CoordMissile Position.x Position.y Map}
	 items(mine:Items.mine sonar:Items.sonar drone:Items.drone missile:Items.missile-Input.Missile placedmines:Items.placedmines)
      elseif Rnd == 1 && Items.sonar > Input.Sonar then KindFire = sonar
	 items(mine:Items.mine sonar:Items.sonar-Input.Sonar drone:Items.drone missile:Items.missile placedmines:Items.placedmines)
      elseif Rnd == 2 && Items.drone > Input.Drone then KindFire = {CoordDrone}
	 items(mine:Items.mine sonar:Items.sonar drone:Items.drone-Input.Drone missile:Items.missile placedmines:Items.placedmines)	       
      else KindFire = null
      end
   end

   fun{Boucle List N Acc}
      if List == nil then nil
      else
	 if N == Acc then {Boucle List.2 N Acc+1} 
	 else List.1|{Boucle List.2 N Acc+1}
	 end
      end
   end

   fun{Size List Size}
      if List == nil then Size
      else {Size List Size+1}
      end
   end
      
   fun{FireMine ID Mine Item}
      if {Size Items.placedmines 0} == 0 then null
      else
	 local Rnd NewItem in
	    Rnd = ({OS.rand} mod {Size Items.placedmines 0})+1
	    Mine={Nth Items.placedmines Rnd}
	    Boucle{Item Rnd 1}
	 end
      end
	    
   end

   fun{IsSurface ID Answer Surface}
      Answer = Surface
      Surface
   end

   fun{SayMove ID Direction}
      true
   end

   fun{SaySurface ID}
      true
   end

   fun{SayCharge ID KindItem}
      true
   end

   fun{SayMinePlaced ID}
      true
   end

   fun{SayMissileExplode ID Position Message Life OurPos}
       Dist in
      Dist = {Abs Position.x-OurPos.x} + {Abs Position.y-OurPos.y}
      if(Dist >= Input.MaxDistanceMissile) then
	 Message = null
	 Life
      elseif (Dist < Input.MaxDistanceMissile && Dist >= Input.MinDistanceMissile) then
	    if Life-1 >0  then
	       Message = sayDamageTaken(ID 1 Life-1)
	       Life-1
	    else
	       Message = sayDeath(ID)
	       Life-1
	    end
      else
	 if(Life-2 >0)  then
	       Message = sayDamageTaken(ID 1 Life-2)
	       Life-2
	    else
	       Message = sayDeath(ID)
	       Life-2
	   end
	 end
      end	    
   end

   fun{SayMineExplode ID Position Message Life OurPos}
      Dist in
      Dist = {Abs Position.x-OurPos.x} + {Abs Position.y-OurPos.y}
      if(Dist >= Input.MaxDistanceMine) then
	 Message = null
	 Life
      elseif (Dist < Input.MaxDistanceMine && Dist >= Input.MinDistanceMine) then
	    if Life-1 >0  then
	       Message = sayDamageTaken(ID 1 Life-1)
	       Life-1
	    else
	       Message = sayDeath(ID)
	       Life-1
	    end
      else
	 if(Life-2 >0)  then
	       Message = sayDamageTaken(ID 1 Life-2)
	       Life-2
	    else
	       Message = sayDeath(ID)
	       Life-2
	   end
	 end
      end
   end

   fun{SayPassingDrone Drone ID Answer}
     true 
   end

   fun{SayAnswerDrone Drone ID Answer}
      true
   end

   fun{SayPassingSonar ID Answer}
      true
   end

   fun{SayAnswerSonar ID Answer}
      true
   end

   fun{SayDeath ID}
      true
   end

   fun{SayDamageTaken ID Damage LifeLeft}
      true
   end

in

   fun{StartPlayer Color ID}
      Stream
      Port
   in
      {NewPort Stream Port}
      
      thread
	 {TreatStream Stream ID Position Path Items Input.maxDamage Surface}
      end
      Port
   end
   proc{TreatStream Stream ID Path Items Life Surface} % has as many parameters as you want
      case Stream of
	 nil then skip
      []initPosition(ID Position)|S then
	 {TreatStream Stream ID {InitPosition ID Position} Path Items Life Surface}
      []move(ID Position Direction)|S then NewState in
	 {TreatStream Stream ID {Move ID Position Direction Path} Items Life Surface}
      []dive|S then 
	 {TreatStream Stream ID Path Items Life Surface}
      []chargeItem(ID KindItem)|S then
	 {TreatStream Stream ID Path {ChargeItems ID KindItems Items} Life Surface}
      []fireItem(ID KindFire)|S then 
	 {TreatStream Stream ID Path {FireItems ID KindFire Items} Life Surface}
      []fireMine(ID Mine)|S then 
	 {TreatStream Stream ID Path {FireMine ID KindFire Items} Life Surface}
      []isSurface(ID Answer)|S then
	 {TreatStream Stream ID Path Items Life {IsSurface ID Answer Surface}}
      []sayMove(ID Direction)|S then skip
      []saySurface(ID)|S then skip
      []sayCharge(ID KindItem)|S then skip
      []sayMinePlaced(ID)|S then skip
      []sayMissileExplode(ID Position Message)|S then
	 {TreatStream Stream ID Path Items {SayMissileExplode(ID Position Message Life Path.1)}}
      []sayMineExplode(ID Position Message)|S then skip
	 {TreatStream Stream ID Path Items {SayMineExplode(ID Position Message Life Path.1)}}
      []sayPassingDrone(Drone ID Answer)|S then skip
      []sayAnswerDrone(Drone ID Answer)|S then skip
      []sayPassingSonar(ID Answer)|S then skip
      []sayAnswerSonar(ID Answer)|S then skip
      []sayDeath(ID)|S then skip
      []sayDamageTaken(ID Damage LifeLeft)|S then skip
      end
   end
end