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
   
   
   fun{InitPosition ID Position)
      X Y Map NRow NCol in
      Map = Input.Map
      CurrentMap = Map
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
      []H|T then if H.x==X || H.y==Y then false
		 else {NotOnPath X Y T}end
      end
   end

   fun{Move ID Position Direction Path)
      Dir Map X Y in
      Map = Input.Map
      X = PlayerPosition.x
      Y = PlayerPosition.y
      Dir = {Os.rand} +1 mod 50
      if Dir == 0 then Position = Path.1
	 Direction = surface
	 nil
      else Dir = {Abs{Os.rand}} mod 4
	 case Dir of
	    0 then if {Nth {Nth Map X+1} Y}==EMPTY andthen {NotOnPath X+1 Y Path}
		   then Position = pt(x:X+1 y:Y)
		      Direction = south
		      Position|Path
		   else {Move ID Position Direction Path} end
	    1 then if {Nth {Nth Map X-1} Y}==EMPTY andthen {NotOnPath X-1 Y Path}
		   then Position = pt(x:X-1 y:Y)
		      Direction = north
		      Position|Path
		   else {Move ID Position Direction Path} end
	    2 then if {Nth {Nth Map X} Y-1}==EMPTY andthen {NotOnPath X Y-1 Path}
		   then Position = pt(x:X y:Y-1)
		      Direction = west
		      Position|Path
		   else {Move ID Position Direction Path} end
	    3 then if {Nth {Nth Map X} Y+1}==EMPTY andthen {NotOnPath X Y+1 Path}
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
	 0 then items(mine:Items.mine+1 sonar:Items.sonar drone:Items.drone missile:Items.missile)
	 if Items.mine + 1 mod Input.Mine == 0 then KindItem = mine
	 else KindItem = null end
      []1 then items(mine:Items.mine sonar:Items.sonar+1 drone:Items.drone missile:Items.missile)
	 if Items.sonar + 1 mod Input.Sonar == 0 then KindItem = sonar
	 else KindItem = null end
      []2 then items(mine:Items.mine sonar:Items.sonar drone:Items.drone+1 missile:Items.missile)
	 if Items.drone + 1 mod Input.Drone == 0 then KindItem = drone
	 else KindItem = null end
      []3 then items(mine:Items.mine sonar:Items.sonar drone:Items.drone missile:Items.missile+1)
	 if Items.missile + 1 mod Input.Missile == 0 then KindItem = missile
	 else KindItem = null end	  
      end
   end

   fun{FireItem ID KindFire Items Position}
      Rnd in
      Rnd = {Abs{Os.rand}} mod 4
      if Rnd == 0 andthen Items.mine > Input.Mine then KindFire = {CoordMine Position.x Position.y}
	 items(mine:Items.mine-Input.Mine sonar:Items.sonar drone:Items.drone missile:Items.missile)
      elseif Rnd == 3 andthen Items.missile > Input.Missile then KindFire = {CoordMissile Position.x Position.y}
	 items(mine:Items.mine sonar:Items.sonar drone:Items.drone missile:Items.missile-Input.Missile)
      elseif Rnd == 1 andthen Items.sonar > Input.Sonar then KindFire = sonar
	 items(mine:Items.mine sonar:Items.sonar-Input.Sonar drone:Items.drone missile:Items.missile)
      elseif Rnd == 2 andthen Items.drone > Input.Drone then KindFire = {CoordDrone Position.x Position.y}
	 items(mine:Items.mine sonar:Items.sonar drone:Items.drone-Input.Drone missile:Items.missile)	       
      else KindFire = null
      end
   end

   fun{FireMine ID Mine}
      %
   end

   fun{IsSurface ID Answer}
      %
   end

   fun{SayMove ID Direction}
      %
   end

   fun{SaySurface ID}
      %
   end

   fun{SayCharge ID KindItem}
      %
   end

   fun{SayMinePlaced ID}
      %
   end

   fun{SayMissileExplode ID Position Message}
      %
   end

   fun{SayMineExplode ID Position Message}
      %
   end

   fun{SayPassingDrone Drone ID Answer}
      %
   end

   fun{SayAnswerDrone Drone ID Answer}
      %
   end

   fun{SayPassingSonar ID Answer}
      %
   end

   fun{SayAnswerSonar ID Answer}
      %
   end

   fun{SayDeath ID}
      %
   end

   fun{SayDamageTaken ID Damage LifeLeft}
      %
   end

in

   fun{StartPlayer Color ID}
      Stream
      Port
   in
      {NewPort Stream Port}
      
      thread
	 {TreatStream Stream ID}
      end
      Port
   end
   proc{TreatStream Stream ID} % has as many parameters as you want
      case Stream of
	 nil then skip
      []initPosition(ID Position)|S then NewState in
	 NewState = {InitPosition State ID Position}
	 {TreatStream S NewState}
      []move(ID Position Direction)|S then NewState in
	 NewState = {Move State ID Position Direction}
	 {TreatStream S NewState}
      []dive|S then NewState in
	 NewState = {Dive State}
	 {TreatStream S NewState}
      []chargeItem(ID KindItem)|S then NewState in
	 NewState = {ChargeItem State ID KindItem}
	 {TreatStream S NewState}
      []fireItem(ID KindFire)|S then NewState in
	 NewState = {FireItem State ID KindFire}
	 {TreatStream S NewState}
      []fireMine(ID Mine)|S then NewState in
	 NewState = {FireMine State ID Mine}
	 {TreatStream S NewState}
      []isSurface(ID Answer)|S then NewState in
	 NewState = {IsSurface State ID Answer}
	 {TreatStream S NewState}
      []sayMove(ID Direction)|S then NewState in
	 NewState = {SayMove State ID Direction}
	 {TreatStream S NewState}
      []saySurface(ID)|S then NewState in
	 NewState = {SaySurface State ID}
	 {TreatStream S NewState}
      []sayCharge(ID KindItem)|S then NewState in
	 NewState = {SayCharge State ID KindItem}
	 {TreatStream S NewState}
      []sayMinePlaced(ID)|S then NewState in
	 NewState = {SayMinePlaced State ID}
	 {TreatStream S NewState}
      []sayMissileExplode(ID Position Message)|S then NewState in
	 NewState = {SayMissileExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayMineExplode(ID Position Message)|S then NewState in
	 NewState = {SayMineExplode State ID Position Message}
	 {TreatStream S NewState}
      []sayPassingDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayPassingDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayAnswerDrone(Drone ID Answer)|S then NewState in
	 NewState = {SayAnswerDrone State Drone ID Answer}
	 {TreatStream S NewState}
      []sayPassingSonar(ID Answer)|S then NewState in
	 NewState = {SayPassingSonar State ID Answer}
	 {TreatStream S NewState}
      []sayAnswerSonar(ID Answer)|S then NewState in
	 NewState = {SayAnswerSonar State ID Answer}
	 {TreatStream S NewState}
      []sayDeath(ID)|S then NewState in
	 NewState = {SayDeath State ID}
	 {TreatStream S NewState}
      []sayDamageTaken(ID Damage LifeLeft)|S then NewState in
	 NewState = {SayDamageTaken State ID Damage LifeLeft}
	 {TreatStream S NewState}
      end
   end
end