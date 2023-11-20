function [Matriz_tasa_falla, Matriz_tiempo_interrupcion, Matriz_indisponibilidad, Matriz_kvai]=matrices(Npob,Ntr,cant_ramales,M,tasa_falla,Tsi,TTi,TRi,Ady,Li,grafo1)
Matriz_tasa_falla=zeros(Ntr,Ntr,Npob);
Matriz_tiempo_interrupcion=zeros(Ntr,Ntr,Npob);
Matriz_indisponibilidad=zeros(Ntr,Ntr,Npob);
Matriz_alcance=zeros(Ntr);
Matriz_kvai=zeros(Ntr,Ntr,Npob);

%% Matriz Alcance
for j=1:Ntr
    Matriz_alcance=Matriz_alcance + Ady^(j-1);
end
%% Matrices tasa de falla y matriz de kVAi
for k=1:Npob        %se mueve por todos los cromosomas
        for i=1:Ntr
            for j=1:Ntr
                if M(i,j,k)==1
                    Matriz_tasa_falla(i,j,k)=tasa_falla(i);
                    Matriz_kvai(i,j,k)=Li(j);
                end
                
            end 
        end
end
%% Matriz de tiempo de interrupcion o MLE
for k=1:Npob        
    %Troncal
        for i=1:Ntr-cant_ramales
            for j=1:Ntr
                if M(i,j,k)==1
                    if i==j
                        Matriz_tiempo_interrupcion(i,j,k)=TRi(i); %carga en la diagonal principal los TR"i".
                    else
                        if Matriz_alcance(i,j)==0 % carga TS(i) donde hay ceros, representa nodos aguas arriba de la falla.
                            Matriz_tiempo_interrupcion(i,j,k)=Tsi(i);
                        else
                            Matriz_tiempo_interrupcion(i,j,k)=TTi(i); %carga TT(i) representa nodos aguas abajo de la falla.
                        end
                    end                    
                end 
            end 
            derivaciones=successors(grafo1,i);                  %derivaciones del tramo en falla y troncales posteriores
            indices_troncales=derivaciones<=Ntr-cant_ramales;   %hallamos las trpncales posteriores
            derivaciones=derivaciones(~indices_troncales);      %eliminamos las troncales posteriores y tenemos solo las derivaciones
            Matriz_tiempo_interrupcion(i,derivaciones,k)=TRi(i);%tiempo de indisp. de derivaciones es igual a su troncal en falla
        end
    %Derivaciones
        for i=Ntr-cant_ramales+1:Ntr
            for j=1:Ntr
                if M(i,j,k)==1
                    if i==j
                        Matriz_tiempo_interrupcion(i,j,k)=TRi(i); %carga en la diagonal principal los TR"i".
                    else
                        if Matriz_alcance(i,j)==0 % carga TS(i) donde hay ceros, representa nodos aguas arriba de la falla.
                            Matriz_tiempo_interrupcion(i,j,k)=Tsi(i);
                        else
                            Matriz_tiempo_interrupcion(i,j,k)=TRi(i); %carga TT(i) representa nodos aguas abajo de la falla.
                        end
                    end                    
                end
            end
        end
end
%% Matriz de Indiponibilidad
for k=1:Npob        %se mueve por todos los cromosomas
        
        Matriz_indisponibilidad(:,:,k) = Matriz_tasa_falla(:,:,k).*Matriz_tiempo_interrupcion(:,:,k);
        
end
end