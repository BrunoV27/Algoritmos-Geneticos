function [Matriz_tasa_falla_acoples, Matriz_tiempo_interrupcion_acoples, Matriz_indisponibilidad_acoples, Matriz_kvai_acoples]=matrices_acoples(Npob,Ntr,cant_ramales,M,tasa_falla,Tsi,TTi,TRi,Ady,Li,grafo1,mejores_tele_acoples,bloques)
cant_bloques=zeros(1,Npob);
for k=1:Npob
    existen=~cellfun(@isempty, bloques(k,:));
    cant_bloques(k)=sum(existen);
end
Matriz_tasa_falla_acoples=zeros(Ntr,Ntr,Npob,3);
Matriz_tiempo_interrupcion_acoples=zeros(Ntr,Ntr,Npob,3);
Matriz_indisponibilidad_acoples=zeros(Ntr,Ntr,Npob,3);
Matriz_alcance=zeros(Ntr);
Matriz_kvai_acoples=zeros(Ntr,Ntr,Npob,3);
M_acoples=zeros(Ntr,Ntr,Npob,3); %EL 3 nos indica que por cada cromosoma tenemos 3 opciones, 1 2 o 3 NA

%% Modificamos la Matriz de Estados para que se ajuste a los acoplamientos
for k=1:Npob
    for m=1:3 % 1 2 o 3 NA
        M_acoples(:,:,k,m)=M(:,:,k);
        if mejores_tele_acoples{k}{2}(m) > 0 %Solo si tiene energia restablecida por los acoples nos interesa
            for b1=1:cant_bloques(k)            %bloque en falla
                for b2=1:cant_bloques(k)
                    if b2 > b1 && mejores_tele_acoples{k}{3}(b1,b2,m) == 0
                        indices=bloques{k,b1} <= Ntr-cant_ramales; %Troncales del tramo en falla
                        troncales=bloques{k,b1}(indices);

                        for i=1:length(troncales)
                            for j=1:length(bloques{k,b2})
                                M_acoples(troncales(i),bloques{k,b2}(j),k,m)=0;
                            end
                        end
                        
                    end
                end
            end
        end
    end
end

%% Matriz Alcance
for j=1:Ntr
    Matriz_alcance=Matriz_alcance + Ady^(j-1);
end

%% Matrices tasa de falla y matriz de kVAi
for m=1:3
    for k=1:Npob        %se mueve por todos los cromosomas
        for i=1:Ntr
            for j=1:Ntr
                if M_acoples(i,j,k,m)==1
                    Matriz_tasa_falla_acoples(i,j,k,m)=tasa_falla(i);
                    Matriz_kvai_acoples(i,j,k,m)=Li(j);
                end
            end 
        end
    end
end
%% Matriz de tiempo de interrupcion o MLE
for m=1:3
    for k=1:Npob        
        %Troncal
            for i=1:Ntr-cant_ramales
                for j=1:Ntr
                    if M_acoples(i,j,k,m)==1
                        if i==j
                            Matriz_tiempo_interrupcion_acoples(i,j,k,m)=TRi(i); %carga en la diagonal principal los TR"i".
                        else
                            if Matriz_alcance(i,j)==0 % carga TS(i) donde hay ceros, representa nodos aguas arriba de la falla.
                                Matriz_tiempo_interrupcion_acoples(i,j,k,m)=Tsi(i);
                            else
                                Matriz_tiempo_interrupcion_acoples(i,j,k,m)=TTi(i); %carga TT(i) representa nodos aguas abajo de la falla.
                            end
                        end                    
                    end 
                end 
                derivaciones=successors(grafo1,i);                  %derivaciones del tramo en falla y troncales posteriores
                indices_troncales=derivaciones<=Ntr-cant_ramales;   %hallamos las trpncales posteriores
                derivaciones=derivaciones(~indices_troncales);      %eliminamos las troncales posteriores y tenemos solo las derivaciones
                Matriz_tiempo_interrupcion_acoples(i,derivaciones,k,m)=TRi(i);%tiempo de indisp. de derivaciones es igual a su troncal en falla
            end
        %Derivaciones
            for i=Ntr-cant_ramales+1:Ntr
                for j=1:Ntr
                    if M_acoples(i,j,k,m)==1
                        if i==j
                            Matriz_tiempo_interrupcion_acoples(i,j,k,m)=TRi(i); %carga en la diagonal principal los TR"i".
                        else
                            if Matriz_alcance(i,j)==0 % carga TS(i) donde hay ceros, representa nodos aguas arriba de la falla.
                                Matriz_tiempo_interrupcion_acoples(i,j,k,m)=Tsi(i);
                            else
                                Matriz_tiempo_interrupcion_acoples(i,j,k,m)=TRi(i); %carga TT(i) representa nodos aguas abajo de la falla.
                            end
                        end                    
                    end
                end
            end
    end
end

%% Matriz de Indiponibilidad
for m=1:3
    for k=1:Npob        %se mueve por todos los cromosomas

            Matriz_indisponibilidad_acoples(:,:,k,m) = Matriz_tasa_falla_acoples(:,:,k,m).*Matriz_tiempo_interrupcion_acoples(:,:,k,m);

    end
end
end