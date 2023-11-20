function P2=mutacion(P,P1,Ntr,Npob,cant_ramales,Xmut,N)
Xmut=ceil((Ntr-cant_ramales)*Xmut);   %saca la cantidad en unidades de genes a ser alterados, redondea hacia arriba
for i=1:Npob
   Mut=randperm(Ntr-cant_ramales-1,Xmut)+ones(1,Xmut);      %vector que contiene la posicion de los genes a ser alterados. Ntr-m-1 son lo tramos del troncal menos el 1 y Xmut es la cantidad de mutaciones
   if ~isequal(P(i,:),P1(i,:))  %solo me importa si son desiguales, porque ahi esta uno de los desendientes
       for q=1:Xmut
           if P1(i,Mut(q))==0 && sum(P1(i,:))<=N  %Hasta N ya que hay un interruptor de cabecera que no suma
               P1(i,Mut(q))=1;
           elseif P1(i,Mut(q))==1 && sum(P1(i,:))>2    %Si el cromosoma tiene un solo reconectador la suma sale 2 (reco + Interr cabecesa)
               P1(i,Mut(q))=0;
           end
       end
   end
end
P2=P1;
end