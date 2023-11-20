function mejores=seleccion(FO,Npob) %Seleccion por ruleta ponderada
mejores=zeros(1,Npob/2);    %mejores almacena las pisiciones dentro de la poblacion
q=1:Npob;               %Almacena los indices(ubicacion) de todas las FO de la poblacion

for i=1:Npob/2    
    k=randsample(length(q),2);  %seleccionamos 2 de entre la poblacion restante
    if FO(q(k(1))) <= FO(q(k(2)))
        mejores(i)=q(k(1));
    else
        mejores(i)=q(k(2));
    end
    q(k)=[];                    %Eliminamos los que ya hallan sido seleccionados
end
end