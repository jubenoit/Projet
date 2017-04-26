functor
import
   Input
   OS
   System
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %Update un State avec une liste de tuple contenant les valeurs qui ont changees
   % state(a:1 b:2) + [b#3] = state(a:1 b:3)

   fun {Nth L A B}
      fun {NthRow L A}
		 if L == nil then 1
		 elseif A == 1 then {NthColumn L.1 B}
		 else {NthRow L.2 A - 1}
		 end
      end

      fun{NthColumn L B}
		 if L == nil then 1
		 elseif B == 1 then L.1
		 else {NthColumn L.2 B - 1}
		 end
      end
   in
      {NthRow L A}
   end

   fun{InitPosition State ID Position}
      proc{FindPos X Y}
		 A B
      in
		 A = ({Abs {OS.rand}} mod Input.nRow) + 1
		 B = ({Abs {OS.rand}} mod Input.nColumn) + 1
		 if {Nth Input.map A B} == 0 then X = A Y = B
		 else {FindPos X Y} end
      end
      X Y
   in
      ID = State.id
      {FindPos X Y}
      Position.x = X
      Position.y = Y
      {AdjoinList State [curPos#Position id#ID map#{ModMap State.map Position}]}
   end

   fun{ModMap Map Pos}
      fun{ModColumn Map AccY}
		 if AccY == 1 then 1|Map.2
		 else Map.1|{ModColumn Map.2 AccY - 1}
		 end
      end
      fun{ModRow Map AccX AccY}
		 if AccX == 1 then {ModColumn Map.1 AccY}|Map.2
		 else Map.1|{ModRow Map.2 AccX - 1 AccY}
		 end
      end
   in
      {ModRow Map Pos.x Pos.y}
   end
   
   fun{Move State ID Position Direction}
      fun{PosAleat N}
		 Pos Direct
      in
		 %{System.show 'Aleatoire'}
		 %{System.show N}
		 if N == 0 then false
		 else case {Abs {OS.rand}} mod 4 of 0 then
				 Direct = north 
				 Pos = pt(x:State.curPos.x - 1 y:State.curPos.y)
			  []1 then
				 Direct = west
				 Pos = pt(x:State.curPos.x y:State.curPos.y - 1)
			  []2 then
				 Direct = south
				 Pos = pt(x:State.curPos.x + 1 y:State.curPos.y)
			  []3 then
				 Direct = east
				 Pos = pt(x:State.curPos.x y:State.curPos.y + 1)
			  end
			%{System.show Direct}
			if {Nth State.map Pos.x Pos.y} == 0 then
			   Position = Pos
			   Direction = Direct
			   true
			else
			   {PosAleat N - 1}
			end
		 end 
      end

      proc{PosTurn N}
		 Pos Direct
      in
		 %{System.show 'Turn'}
		 case N of 0 then
			Direct = north
			Pos = pt(x:State.curPos.x - 1 y:State.curPos.y)
		 []1 then
			Direct = west
			Pos = pt(x:State.curPos.x y:State.curPos.y - 1)
		 []2 then
			Direct = south
			Pos = pt(x:State.curPos.x + 1 y:State.curPos.y)
		 []3 then
			Direct = east
			Pos = pt(x:State.curPos.x y:State.curPos.y + 1)
		 []4 then
			Direct = surface
			Pos = State.curPos
		 end
		 if {Nth State.map Pos.x Pos.y} == 0 orelse Direct == surface then
			Position = Pos
			Direction = Direct
		 else
			{PosTurn N + 1}
		 end
      end
   in
      ID = State.id
	  %{System.show State.map}
      if {PosAleat 3} then skip
      else {PosTurn 0}
      end
      if Direction == surface then
		 {AdjoinList State [curPos#Position curDir#Direction map#Input.map]}
      else
		 {AdjoinList State [curPos#Position curDir#Direction map#{ModMap State.map Position}]}
      end
   end

   fun{Dive State}
      {AdjoinList State [curDir#north map#{ModMap State.map State.curPos}]}
   end

   fun{ChargeItem State ID KindItem}
      ID = State.id

      case  {Abs {OS.rand}} mod 4
      of 0 then
		 if State.accMissile + 1 == Input.missile then KindItem = missile
		 else KindItem = null
		 end
		 {AdjoinList State [accMissile#State.accMissile + 1]}
      [] 1 then
		 if State.accMine + 1 == Input.mine then KindItem = mine
		 else KindItem = null
		 end
		 {AdjoinList State [accMine#State.accMine + 1]}
      [] 2 then
		 if State.accSonar + 1 == Input.sonar then KindItem = sonar
		 else KindItem = null
		 end
		 {AdjoinList State [accSonar#State.accSonar + 1]}
      [] 3 then
		 if State.accDrone + 1 == Input.drone then KindItem = drone
		 else KindItem = null
		 end
		 {AdjoinList State [accDrone#State.accDrone + 1]}
      end
   end

   fun{FireItem State ?ID ?KindFire}
      fun{AleaPos Min Max Type}
		 Pos = pt(x:_ y:_)
      in
		 Pos.x = State.curPos.x - Max  + {Abs {OS.rand}} mod (2 * Max +1)
		 Pos.y =  State.curPos.y - Max  + {Abs {OS.rand}} mod (2 * Max +1)
		 if Pos.x > 0 andthen Pos.x =< Input.nRow andthen
			Pos.y > 0 andthen Pos.y =< Input.nColumn andthen
			{Nth Input.map Pos.x Pos.y} == 0 andthen
			{Abs State.curPos.x - Pos.x} + {Abs State.curPos.y - Pos.y} >= Min andthen
			{Abs State.curPos.x - Pos.x} + {Abs State.curPos.y - Pos.y} =< Max
		 then
			if Type == mine orelse
			   {Abs State.curPos.x - Pos.x} + {Abs State.curPos.y - Pos.y} >= 2 then
			   Pos
			else
			   {AleaPos Min Max Type}
			end
		 else {AleaPos Min Max Type}
		 end
      end
   in
      ID = State.id
      if State.accMissile >= Input.missile then
		 KindFire = missile({AleaPos Input.minDistanceMissile Input.maxDistanceMissile missile})
		 {AdjoinList State [accMissile#(State.accMissile - Input.missile)]}
      elseif State.accMine >= Input.mine then
		 Pos = {AleaPos Input.minDistanceMine Input.maxDistanceMine mine}
      in
		 KindFire = mine(Pos)
		 {AdjoinList State [accMine#(State.accMine - Input.mine) posMine#(Pos|State.posMine)]}
      elseif State.accSonar >= Input.sonar then
		 KindFire = sonar()
		 {AdjoinList State [accSonar#(State.accSonar - Input.sonar)]}
	  elseif State.accDrone >= Input.drone then
		 case {Abs {OS.rand}} mod 2
		 of 0 then KindFire = drone(row {Abs {OS.rand} mod Input.nRow +1})
		 [] 1 then KindFire = drone(column {Abs {OS.rand} mod Input.nColumn +1})
		 end
		 {AdjoinList State [accDrone#(State.accDrone - Input.drone)]}
      else
		 KindFire = null
		 State
      end
   end

   fun{FireMine State ID Mine}
	  fun{ChoseMine LMine}
		 case LMine of nil then null
		 []HMine|TMine then
			if {Abs State.curPos.x - HMine.x} + {Abs State.curPos.y - HMine.y} >= 2 then HMine
			else {ChoseMine TMine}
			end
		 end
	  end

	  fun{RemoveMine LMine Mine}
		 case LMine of nil then nil
		 []HMine|TMine then if HMine == Mine then TMine
							else HMine|{RemoveMine TMine Mine}
							end
		 end
	  end
   in
      ID = State.id
      if State.posMine == nil then
		 Mine = null
		 State
      else
		 Mine = {ChoseMine State.posMine}
		 if State.timeMine == 1 orelse Mine == null then 
			{AdjoinList State [timeMine#0]} 
		 else
			{AdjoinList State [timeMine#1 posMine#{RemoveMine State.posMine Mine}]}
		 end
      end
   end

   fun{IsSurface State ?ID ?Answer}
      if State.life =< 0 then
		 ID = null
		 Answer = null
		 State
      else
		 ID = State.id
		 Answer = State.curDir == surface
		 State
      end
   end

   fun{SayMove State ID Direction}
      {System.show Direction}
      State
   end

   fun{SaySurface State ID}
      {System.show "Surface"}
      {System.show ID}
      State
   end

   fun{SayCharge State ID KindItem}
      {System.show KindItem}
      State
   end

   fun{SayMinePlaced State ID}
      {System.show 'Mine Placed'}
      State
   end

   fun{SayMissileExplode State ID Position ?Message}
      Dist in
      Dist = {Abs State.curPos.x - Position.x} + {Abs State.curPos.y - Position.y}
      if State.life =< 0 then
		 Message = null
		 State
      elseif Dist == 0 then
		 if State.life - 2 > 0 then
			Message = sayDamageTaken(State.id 2 State.life - 2)
			{AdjoinList State [life#State.life - 2]}
		 else
			Message = sayDeath(State.id)
			{AdjoinList State [life#0]}
		 end
      elseif Dist == 1 then
		 if State.life - 1 > 0 then
			Message = sayDamageTaken(State.id 1 State.life - 1)
			{AdjoinList State [life#State.life - 1]}
		 else
			Message = sayDeath(State.id)
			{AdjoinList State [life#0]}
		 end
      else
		 Message = null%sayDamageTaken(State.id 0 State.life)
		 State
      end
   end

   fun{SayMineExplode State ID Position Message}
      {SayMissileExplode State ID Position Message}
   end

   fun{SayPassingDrone State Drone ID Answer}
      Type
      X
   in
      drone(Type X) = Drone
      if Type == row then
		 Answer = State.curPos.x == X
      else Answer = State.curPos.y == X
      end
      State
   end

   fun{SayAnswerDrone State Drone ID Answer}
      State
   end

   fun{SayPassingSonar State ID Answer}
      if {Abs {OS.rand}} mod 2 == 0 then
		 Answer = pt(x:State.curPos.x y:({Abs {OS.rand}} mod Input.nColumn + 1))
      else
		 Answer = pt(x:({Abs {OS.rand}} mod Input.nRow + 1) y:State.curPos.y)
      end
      State
   end

   fun{SayAnswerSonar State ID Answer}
      State
   end

   fun{SayDeath State ID}
      State
   end

   fun{SayDamageTaken State ID Damage LifeLeft}
      State
   end

in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   fun{StartPlayer Color ID}
      Stream
      Port
      State
   in
      Port = {NewPort Stream}
      State = submarine(curPos:pt(x:_ y:_) curDir:surface accMissile:0 accMine:0 accSonar:0 accDrone:0 posMine:nil timeMine:1 life:Input.maxDamage id:ID map:Input.map)
      thread
		 {TreatStream Stream State}
      end
      Port
   end
   
   proc{TreatStream Stream State}   
      case Stream
      of nil then skip
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
      else
		 skip
      end
   end
end