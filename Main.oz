functor
import
   GUI
   Input
   PlayerManager
   OS
   System
define
   PortGUI
   PortPlayer
   AskForSetUp
   Ports
   IDs
   GlobalMsg
   MissileExplodeMsg
   MineExplodeMsg
   PassingDroneMsg
   PassingSonarMsg
   Msg
   StillPlaying
   SurfaceMin
   CreationSurface
   Remove
   TourParTour
   ThreadLaunch
   Simultane
   StartSurface
   
in
   %Initialisation du Port GUI
   PortGUI = {GUI.portWindow}
   {Send PortGUI buildWindow}

   %Initialisation des port Joueurs
   fun{PortPlayer Players ID}
      case Players
      of nil#nil then nil
      [](H1|T1)#(H2|T2) then
	 {PlayerManager.playerGenerator H1 H2 id(id:ID color:H2 name:H1)}|{PortPlayer T1#T2 ID+1}
      end
   end

   Ports = {PortPlayer Input.players#Input.colors 1}

   %Set up des joueurs
   fun{AskForSetUp Ports}
      case Ports
      of nil then nil
      []H|T then
	 local ID Position in
	    {Send H initPosition(ID Position)}
	    {Send PortGUI initPlayer(ID Position)}
	    ID|{AskForSetUp T}
	 end
      end
   end
   IDs = {AskForSetUp Ports}

   %Messages
   proc{GlobalMsg Msg P}
      case P of nil then skip
      []H|T then
	 {Send H Msg}
	 {GlobalMsg Msg T}
      end
   end
   fun{MissileExplodeMsg ID Position P}
      case P of nil then nil
      []H|T then
	 local Message in
	    {Send H sayMissileExplode(ID Position Message)}
	    case Message of null then {MissileExplodeMsg ID Position T}
	    []sayDeath(X) then
	       {GlobalMsg Message Ports}
	       {Send PortGUI removePlayer(X)}
	       X|{MissileExplodeMsg ID Position T}
	    []sayDamageTaken(X D L) then
	       {GlobalMsg Message Ports}
	       {Send PortGUI lifeUpdate(X L)}
	       {MissileExplodeMsg ID Position T}
	    end
	 end
      end
   end
   fun{MineExplodeMsg ID Position P}
      case P of nil then nil
      []H|T then
	 local Message in
	    {Send H sayMineExplode(ID Position Message)}
	    case Message of null then {MineExplodeMsg ID Position T}
	    []sayDeath(X) then
	       {GlobalMsg Msg Ports}
	       {Send PortGUI removePlayer(X)}
	       X|{MineExplodeMsg ID Position T}
	    []sayDamageTaken(X D L) then
	       {GlobalMsg Msg Ports}
	       {Send PortGUI lifeUpdate(X L)}
	       {MineExplodeMsg ID Position T}
	    end
	 end
      end
   end
   proc{PassingDroneMsg Drone ID P}
      case P of nil then skip
      []H|T then
	 local I Answer in
	    {Send H sayPassingDrone(Drone I Answer)}
	    {Send {Nth Ports ID} sayAnswerDrone(Drone I Answer)}
	    {PassingDroneMsg Drone ID T}
	 end
      end
   end
   proc{PassingSonarMsg ID P}
      case P of nil then skip
      []H|T then
	 local I Answer Drone in
	    {Send H sayPassingSonar(Drone I Answer)}
	    {Send {Nth Ports ID} sayAnswerDrone(Drone I Answer)}
	    {PassingDroneMsg Drone ID T}
	 end
      end
   end
    %Fonctions Secondaire utilis�es
   fun{SurfaceMin Joueur Surface Acc Value}
      case Surface of nil then nil
      []H|T then
	 if Joueur == Acc then Value|{SurfaceMin Joueur T Acc+1 Value}
	 else H|{SurfaceMin Joueur T Acc+1 Value}
	 end
      end
   end
   fun{StillPlaying Joueur List}
      case List of nil then false
      []H|T then
	 if H==Joueur then true
	 else {StillPlaying Joueur T}
	 end
      end
   end
   fun{Remove List ListToRemove}
      case List of nil then nil
      []H|T then
	 if H==ListToRemove.1 then {Remove T ListToRemove.2}
	 else H|{Remove T ListToRemove}
	 end
      end
   end
   fun{CreationSurface N}
      if N==0 then nil
      else
	 2|{CreationSurface N-1}
      end
   end
   %Partie Tour par Tour
   proc{TourParTour Joueur SurfaceNum Alive}
      {System.show 1}
      /*if({StillPlaying Joueur Alive}==false) then
	 {System.show 2}
	 {TourParTour Joueur+1 SurfaceNum Alive} end */%Le joueur est d�ja mort et ne peut plus jouer
      if({Nth SurfaceNum Joueur}>1) then %Test si le joueur peut jouer ce tour
	 local NewSurf in %si non
	    {System.show r}
	    NewSurf = {SurfaceMin Joueur SurfaceNum 1 {Nth SurfaceNum Joueur}-1}
	    if(Joueur ==  Input.nbPlayer) then {TourParTour 1  NewSurf Alive}
	    else {TourParTour Joueur+1 NewSurf Alive}
	    end
	 end
      else %Si oui
	 local NewSurf CurrentPort RemoveList RemoveList2 TempList FinalList in
	    CurrentPort = {Nth Ports Joueur}
	    {System.show 3}
	    local  ID Position Direction in
	    %Si on est au premier tour ou qu'on vient de plonger
	       if({Nth SurfaceNum Joueur}==1) then
		  NewSurf = {SurfaceMin Joueur SurfaceNum 1 0}
		  {Send CurrentPort dive}
		  {System.show surf}
	       else NewSurf = SurfaceNum
	       end
	    %Choix de la direction
	       {Send CurrentPort move(ID Position Direction)}
	       if(Direction == surface) then
		  {GlobalMsg saySurface(ID) Ports}
		  {Send PortGUI surface(ID)}
		  {System.show hasSurf}
		  local Surf in
		     Surf = {SurfaceMin Joueur NewSurf 1 Input.turnSurface+1}
		     {System.show Ii}
		     if(Joueur==Input.nbJoueur) then
			{System.show la}
			{TourParTour 1 Surf Alive}
		     else {TourParTour Joueur+1 Surf Alive}
		     end
		  end
	       else
		  {GlobalMsg sayMove(ID Direction) Ports}
		  {Send PortGUI movePlayer(ID Position)}
		  {System.show hasmove}
	       end
	    end
	    %Autorisation de charger un item
	    local ID KindItem in
	       {System.show test}
	       {Send CurrentPort chargeItem(ID KindItem)}
	       if(KindItem \= null) then {GlobalMsg sayCharge(ID KindItem) Ports} end
	    end
	    %Autorisation de utiliser un item
	    local ID KindFire in
	       {Send CurrentPort fireItem(ID KindFire)}
	       case KindFire of null then skip
	       []missile(P) then
		  {System.show mis}
		  RemoveList = {MissileExplodeMsg ID P Ports}
	       []mine(P) then
		  {System.show ine}
		  {Send PortGUI putMine(ID P)}
		  {GlobalMsg sayMinePlaced(ID) Ports}
	       []drone(X Y) then
		  {System.show dro}
		  {PassingDroneMsg drone(X Y) ID Ports}
	       []sonar then
		  {System.show ds}
		  {PassingSonarMsg ID Ports}
	       end
	    end
	    %Autorisation de activer une mine
	    local ID Mine in
	       {Send CurrentPort fireMine(ID Mine)}
	       case Mine of null then skip
	       []mine(P) then
		  RemoveList2 = {MineExplodeMsg ID P Ports}
		  {Send PortGUI removeMine(ID P)}
	       end
	    end
	    {System.show re}
	  % TempList={Remove Alive RemoveList}
	  % FinalList={Remove TempList RemoveList2}
	   /* if(FinalList.2==nil) then skip %le joueur a gagn�
	    else*/
	       {System.show turn}
	       if(Joueur == Input.nbPlayer) then
		  {TourParTour 1 NewSurf Alive}
	       else
		  {TourParTour Joueur+1 NewSurf Alive}
	       end%Le tour est finit et le prochain joueur peut commencer
	    %end
	 end
      end
   end

   proc{ThreadLaunch Port}
      case Port of nil then skip
      []H|T then
	 thread
	    {Simultane 1 1 H}
	 end
	 {ThreadLaunch T}
      end
   end
   %Mode Simultan�
   proc{Simultane First Surface Port}
      %Verifie si le joueur doit attendre
      if(First == 1 orelse Surface == 1) then
	 {Delay Input.turnSurface}
	 {Send Port dive}
      end

      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

      local ID Position Direction in
	 {Send Port move(ID Position Direction)}
	 if(direction==surface) then
	    {GlobalMsg saySurface(ID) Ports}
	    {Send PortGUI Surface(ID)}
	    {Simultane 0 1 Port}
	 else
	    {GlobalMsg sayMove(ID Direction) Ports}
	    {Send PortGUI movePlayer(ID Position)}
	 end
      end

      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

      local ID KindItem in
	 {Send Port chargeItem(ID KindItem)}
	 if(KindItem \= null) then {GlobalMsg sayCharge(ID KindItem) Ports} end
      end

      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

      local RemoveList RemoveList2 in
	 local ID KindFire in
	    {Send Port fireItem(ID KindFire)}
	    case KindFire of null then skip
	    []missile(P) then RemoveList = {MissileExplodeMsg ID P Ports}
	    []mine(P) then
	       {Send PortGUI putMine(ID P)}
	       {GlobalMsg sayMinePlaced(ID) Ports}
	    []drone(X Y) then {PassingDroneMsg drone(X Y) ID Ports}
	    []sonar then {PassingSonarMsg ID Ports}
	    end
	 end

	 {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

	 local ID Mine in
	    {Send Port fireMine(ID Mine)}
	    case Mine of null then skip
	    []mine(P) then
	       RemoveList2 = {MineExplodeMsg ID P Ports}
	       {Send PortGUI removeMine(ID P)}
	    end
	 end

	 {Simultane 0 0 Port}
      end
   end
   %Lancement du jeu
   StartSurface = {CreationSurface Input.nbPlayer}
   if(Input.isTurnByTurn == true) then {TourParTour 1 StartSurface IDs}
   else {ThreadLaunch Port}
   end
end