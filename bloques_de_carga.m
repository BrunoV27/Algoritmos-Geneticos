function [bloques, carga_en_bloques]=bloques_de_carga(grafo1,mejores_5_FO,Ntr,cant_ramales,Li)

[cant_mejores_FO,~]=size(mejores_5_FO{1});

%Primero creamos los bloques
bloques={};
for i=1:cant_mejores_FO   %se mueve por los 5 cromosomas
    cromosoma=mejores_5_FO{1}(i,:);
    recon=find(cromosoma); %El primero es un interruptor de cabecera
    
    for j=1:length(recon)
        memoria=[];
        for k=1:length(recon)
            if k>j
                w=shortestpath(grafo1,recon(j),recon(k));
                if ~isempty(w)
                    w(end)=[];
                else
                    w=bfsearch(grafo1,recon(j))';
                end
                if sum(ismember(w,recon))==1
                    memoria=[memoria,w];
                end
            elseif j==length(recon) && k==length(recon)
                w=bfsearch(grafo1,recon(j))';
                memoria=[memoria,w];
            end
        end
    bloques{i,j}=memoria;
    end
end

%agregamos las derivacion y eliminamos los duplicado
[cant_mejores_FO,cant_bloques]=size(bloques);
for i=1:cant_mejores_FO
    cromosoma=mejores_5_FO{1}(i,:);
    recon=find(cromosoma); %El primero es un interruptor de cabecera
    for j=1:cant_bloques
        
        for k=1:length(bloques{i,j})
            if bloques{i,j}(k)<=Ntr-cant_ramales
                Sucesores=successors(grafo1,bloques{i,j}(k))';      %en esta variable se almacena las derivaciones del tramo y tambien el trocal posterior (debemos eliminar este ultimo)
                indices=Sucesores > Ntr-cant_ramales;                %Nos da el valor de las derivaciones de cada tramo troncal
                Sucesores(~indices)=[];                              %las agregamos
                bloques{i,j}=[bloques{i,j},Sucesores];              %agregamos la derivaciones al bloque
                
                %debemos hallar las derivaciones en cascada si existen
                for m=1:sum(indices) 
                    cascadas=bfsearch(grafo1,Sucesores(m))';
                    bloques{i,j}=[bloques{i,j},cascadas];   %agregamos las derivaciones en cascada
                end
            end
        end
        
        %buscamos y agregamos las troncales que se desvian del trayecto principal
        indices=bloques{i,j}<=Ntr-cant_ramales;
        Troncales=bloques{i,j}(indices);
        for k=1:sum(indices)
            Sucesores=successors(grafo1,Troncales(k))';
            indices_ramales=Sucesores>Ntr-cant_ramales;
            Sucesores(indices_ramales)=[];                         %Eliminamos los ramales. Ahora solo contiene los sucesores troncales
            Sucesores=Sucesores(~ismember(Sucesores,Troncales));    %Guardamos los troncales  que no pertenecen al tramo original
            Sucesores=Sucesores(~ismember(Sucesores,recon));        %Eliminamos si pertenece a el siguiente bloque
            for m=1:length(Sucesores)
                faltantes=bfsearch(grafo1,Sucesores(m))';
                bloques{i,j}=[bloques{i,j},faltantes];   %agregamos los troncales faltantes
            end
        end
        bloques{i,j}=unique(bloques{i,j});   %eliminamos los tramos repetidos en el vector
    end
end

%Definimos la carga contenida en cada bloque
carga_en_bloques=zeros(cant_mejores_FO,cant_bloques); %Matriz que contiene la carga de cada bloque en sus filas. Cada fila es para los distintos cromosomas
for i=1:cant_mejores_FO
    for j=1:cant_bloques
        carga_en_bloques(i,j)=sum(Li(bloques{i,j}));
    end
end
end