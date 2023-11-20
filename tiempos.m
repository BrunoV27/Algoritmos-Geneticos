function [Tci, Tsi, Tfi, TTi, TRi]=tiempos(tiempo_seccionamiento,tiempo_reparo,longitudes_tramos,Ntr,grafo1,cant_ramales,V)
%% Calculo de las Tci
Tci=zeros(Ntr,1);
%Para la troncal
for i=1:Ntr-cant_ramales
    if i==1
        Tci(i)=longitudes_tramos(i)/V;
    else
        trayecto=shortestpath(grafo1,1,i);
        trayecto=trayecto(1:end-1);
        Tci(i)=sum(longitudes_tramos(trayecto))/V;
    end
end
%Para las derivaciones
for i=Ntr-cant_ramales+1:Ntr
    trayecto=shortestpath(grafo1,1,i);
    trayecto=trayecto(1:end-2);  %hasta la cabecera del tramo troncal que le contiene
    Tci(i)=sum(longitudes_tramos(trayecto))/V;
end
%% Calculo de las Tsi
Tsi = Tci + tiempo_seccionamiento;

%% Calculo de las Tfi
Tfi=zeros(Ntr,1);
for i=1:Ntr-cant_ramales
    nodo_anterior=predecessors(grafo1,i);                     %Halla el tramo anterior
    nodo_posterior=successors(grafo1,i);                    %Halla los tramos posteriores
    eliminar=nodo_posterior>Ntr-cant_ramales;         %Eliminamos los tramos posteriores que contengan fusibles
    nodo_posterior(eliminar)=[];
  
    cant_sec=length(nodo_anterior)+length(nodo_posterior);  %cantidad de SC a abrir
    
    if i==1
        Tfi(i) = cant_sec*tiempo_seccionamiento(i) + Tci(i);        %El primer tramo siempre aislamos con el SC de la cabecera del 2
    else
        trayecto=shortestpath(grafo1,1,i);      %considerando el tramo de la falla                 
        Tfi(i) = cant_sec*tiempo_seccionamiento(i) + (cant_sec-1)*sum(longitudes_tramos(trayecto))/V + (2-cant_sec)*Tci(i);
    end  
end
for i=Ntr-cant_ramales+1:Ntr
    trayecto=shortestpath(grafo1,1,i);
    trayecto=trayecto(1:end-1);                      %considerando el tramo de la falla
    Tfi(i) = cant_sec*tiempo_seccionamiento(i) + (cant_sec-1)*sum(longitudes_tramos(trayecto))/V + (2-cant_sec)*Tci(i);
end

%% Calculo del tiempo de Transferencia TTi
TTi = Tfi + 5*tiempo_seccionamiento;
%% Calculo del tiempo de reparo TRi
TRi = Tfi + tiempo_reparo;

end