functor
import
   PlayerBasicAI
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of player042basicai then {PlayerBasicAI.portPlayer Color ID}
      []player043basicai then {PlayerBasicAI.portPlayer Color ID}
      end
   end
end