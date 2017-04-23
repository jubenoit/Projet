functor
import
   GUI
   Input
   PlayerManager
define
   PortGUI
   PortPlayes
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
   proc{MissileExplodeMsg ID Position P}
      case P of nil then nil
      []H|T then
	 local Message in
	    {Send H sayMissileExplode(ID Position Message)}
	    case Message of null then {MissileExplodeMsg ID Position T}
	    []sayDeath(X) then
	       {GlobalMsg Msg Ports}
	       {Send PortGUI removePlayer(X)}
	       X|{MissileExplodeMsg ID Position T}
	    []sayDamageTaken(X D L) then
	       {GlobalMsg Msg Ports}
	       {Send PortGUI lifeUpdate(X L)}
	       {MissileExplodeMsg ID Position T}
	    end
	 end
      end
   end
   proc{MineExplodeMsg ID Position P}
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
	 end
      end
   end
   proc{PassingSonarMsg ID P}
      case P of nil then skip
      []H|T then
	 local I Answer in
	    {Send H sayPassingSonar(Drone I Answer)}
	    {Send {Nth Ports ID} sayAnswerDrone(Drone I Answer)}
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
	 if H==L.1 then {RemoveList T ListToRemove.2}
	 else H|{Remove T ListToRemove}
	 end
      end
   end
   fun{CreationSurface N}
      if N==0 then nil
      else 1|{CreationSurface N-1}
      end
   end
   %Partie Tour par Tour
   proc{TourParTour Joueur SurfaceNum Alive}
      if({StillPlaying Joueur Alive}==false) then {TourParTour Joueur+1 SurfaceNum Alive} end %Le joueur est d�ja mort et ne peut plus jouer
      if({Nth Joueur SurfaceNum}>1) then %Test si le joueur peut jouer ce tour
	 local NewSurf in %si non 
	    NewSurf = {SurfaceMin Joueur SurfaceNum 1 {Nth Joueur SurfaceNum}-1}
	    if(Joueur ==  Input.nbPlayers) then {TourParTour 1  NewSurf Alive}
	    else {TourParTour Joueur+1 NewSurf Alive}
	    end
	 end
      else %Si oui
	 local CurrentPort RemoveList RemoveList2 TempList FinalList in
	    CurrentPort = {Nth Ports Joueur}
	    local NewSurf ID Position Direction in
	    %Si on est au premier tour ou qu'on vient de plonger
	       if({Nth Joueur SurfaceNum}==1) then
		  NewSurf = {SurfaceMin Joueur SurfaceNum 1 0}
		  {Send CurrentPort dive}
	       else NewSurf = SurfaceNum
	       end
	    %Choix de la direction
	       {Send CurrentPort move(ID Position Direction)}
	       if(Direction == surface) then
		  {GlobalMsg saySurface(ID) Ports}
		  {Send PortGUI surface(ID)}
		  local Surf in
		     Surf = {SurfaceMin Joueur NewSurf 1 Input.turnSurface+1}
		     if(Joueur==Input.nbJoueur) then
			{TourParTout 1 Surf Alive}
		     else {TourParTour Joueur+1 Surf}
		     end
		  end
	       else
		  {GlobalMsg sayMove(ID Direction) Ports}
		  {Send PortGUI movePlayer(ID Position)}
	       end
	    end
	    %Autorisation de charger un item
	    local ID KindItem in
	       {Send CurrentPort chargeItem(ID KindItem)}
	       if(KindItem != null) then {Global Msg sayCharge(ID KindItem)} end
	    end
	    %Autorisation de utiliser un item
	    local ID KindFire in
	       {Send CurrentPort fireItem(ID KindFire)}
	       case KindFire of null then skip
	       []missile(P) then RemoveList = {MissileExplodeMsg ID P Ports}
	       []mine(P) then
		  {Send PortGUI putMine(ID P)}
		  {GlobalMsg sayMinePlaced(ID)}
	       []drone(X Y) then {PassingDroneMsg Drone ID P}
	       []sonar then {PassingSonarMsg ID P}
	       end
	    end
	    %Autorisation de activer une mine
	    local ID Mine in
	       {Send CurrentPort fireMine(ID Mine)}
	       case Mine of null then skip
	       []mine(P) then
		  RemoveList2 = {MineExplodedMsg ID P Ports}
		  {Send PortGUI removeMine(ID P)}
	       end
	    end
	    TempList={Remove Alive RemoveList}
	    FinalList={Remove TempList RemoveList2}
	    if(FinalList.2==nil) then skip %le joueur a gagn�
	    else
	       if(Joueur == Input.nbPlayers) then
		  {TourParTour 1 NewSurf FinalList}
	       else
		  {TourParTour Joueur+1 NewSurf FinalList}
	       end%Le tour est finit et le prochain joueur peut commencer
	    end
	 end
      end
   end

   proc{ThreadLauch Port}
      case Port of nil then skip
      []H|T then
	 thread
	    {Simultane 1 1 H}
	 end
	 {TreadLauch T}
      end
   end
   %Mode Simultan�
   proc{Simultane First Surface Port}
      %Verifie si le joueur doit attendre
      if(First == 1 || Surface == 1) then
	 {Delay Input.turnSurface}
	 {Send Port dive}
      end

      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

      local ID Position Direction in
	 {Send Port move(ID Position Direction)}
	 if(direction==surface) then
	    {GlobalMsg saySurface(ID)}
	    {Send PortGUI Surface(ID)}
	    {Simultane 0 1 Port}
	 else
	    {GlobalMsg sayMove(ID Direction)}
	    {Send PortGUI movePlayer(ID Position)}
	 end
      end

      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

      local ID KindItem in
	 {Send Port chargeItem(ID KindItem)}
	 if(KindItem != null) then {Global Msg sayCharge(ID KindItem)} end
      end

      {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

      local RemoveList RemoveList2 in
	 local ID KindFire in
	    {Send Port fireItem(ID KindFire)}
	    case KindFire of null then skip
	    []missile(P) then RemoveList = {MissileExplodeMsg ID P Ports}
	    []mine(P) then
	       {Send PortGUI putMine(ID P)}
	       {GlobalMsg sayMinePlaced(ID)}
	    []drone(X Y) then {PassingDroneMsg Drone ID P}
	    []sonar then {PassingSonarMsg ID P}
	    end
	 end

	 {Delay (({OS.rand} mod (Input.thinkMax - Input.thinkMin))+ Input.thinkMin)}

	 local ID Mine in
	    {Send Port fireMine(ID Mine)}
	    case Mine of null then skip
	    []mine(P) then
	       RemoveList2 = {MineExplodedMsg ID P Ports}
	       {Send PortGUI removeMine(ID P)}
	    end
	 end

	 {Simultane 0 0 Port}
      end
   end
   %Lancement du jeu
   StartSurface = {CreationSurface Input.nbPlayers}
   if(Input.isTurnByTurn == true) then {TourParTour 1 StartSurface IDs}
   else {ThreadLauch Port}
   end
end