function [adyacencia_bloques, alimentadores_bloques, cromo_acoples, grafos_bloques, mejores_tele_acoples]=configuracion_acoples(grafo1,acoplamientos,bloques,carga_en_bloques,demanda_asumible)

ubicaciones_acoples=find(cell2mat(acoplamientos(:,1))); %Tramos en donde se encuentran los acoplamientos en el alimentador y con que alimentador esta conectado
acoples_disp=length(cell2mat(acoplamientos(1,:)))-1; %cantidad maxima de acoplamientos por tramo disponibles
[cant_mejores_FO,~]=size(bloques);
cant_bloques=zeros(1,cant_mejores_FO);
for k=1:cant_mejores_FO
    existen=~cellfun(@isempty, bloques(k,:));
    cant_bloques(k)=sum(existen);
end
cant_bloques_max=max(cant_bloques);

%% Primero averiguamos los bloques que se encuentran adyacentes
adyacencia_bloques={};
for k=1:cant_mejores_FO
    u=0;
    for i=1:cant_bloques(k)    %se desplaza por bloques
        for j=1:cant_bloques(k)    %se desplaza por bloques
            
            if j>i                  %Que vaya comparando con los bloques siguientes ya que con los anteriores ya fue comparado
                
                for a=1:length(bloques{k,i})    %Se desplaza por tramos de los bloques
                    for b=1:length(bloques{k,j})    %Se desplaza por tramos de los bloques
                        
                        caminos=shortestpath(grafo1,bloques{k,i}(a),bloques{k,j}(b));   %Obtenemos los tramos por el que pasa cada tramo del bloque 1 a cada tramo del bloque 2
                        
                        if length(caminos)==2 %Solo puede ser igual a dos cuando los tramos son adyacentes
                            u=u+1;
                            adyacencia_bloques{k,1}(u,:)=[i j]; %Guada los bloques que son adyacentes
                        end
                    end
                end
            end
        end
    end
end

%% Obtener los alimentadores a los que los bloques esten conectados
alimentadores_bloques=cell(cant_mejores_FO,cant_bloques(1)); %Cita los alimentadores a los que estan directamente conectados cada bloque
for k=1:cant_mejores_FO
    for b=1:cant_bloques(k)
        u=0;
        for t=1:length(ubicaciones_acoples)
            if any(bloques{k,b}==ubicaciones_acoples(t)) %Si detecta que el tramo con acople pertenece al bloque lo guarda
                
                for a=1:acoples_disp %Guarda uno o ambos alimentadores acoplables al tramo
                    Alimentador=acoplamientos{ubicaciones_acoples(t),a+1};
                    
                    if Alimentador==0
                        
                    else
                        u=u+1;
                        alimentadores_bloques{k,b}(u,:)=acoplamientos{ubicaciones_acoples(t),a+1};
                    end
                end
            end
        end
        alimentadores_bloques{k,b}=unique(alimentadores_bloques{k,b},'rows','stable'); %Elimina las repeticiones
        if b==1
            alimentadores_bloques{k,b}=[];  %Eliminamos los acoples en la cabecera ya que no nos sirven
        end
    end
end


%% Creamos los cromosomas para los acoples
cromo_acoples=cell(cant_mejores_FO,1);
for k=1:cant_mejores_FO
    num=0; %numero de bloques con acoples
    for b=1:cant_bloques(k)
        if ~isempty(alimentadores_bloques{k,b})
            num=num+1;
        end
    end
    
    num1=0; %numero de posibles combinaciones
    for i=1:num
        num1=num1+nchoosek(num,i);
    end
    
    cromo_acoples{k}=zeros(num1,num);%indica las ubicaciones de los acoples telecomandados 
    for i=1:num1
        bin=dec2bin(i);
        u=0;
        for j=num:-1:num-length(bin)+1
            u=u+1;
            cromo_acoples{k}(i,j)=str2double(bin(length(bin)-u+1));
        end
    end
end

%% Crear Grafos de bloques para cada cromosoma
grafos_bloques=cell(cant_mejores_FO,1);
for k=1:cant_mejores_FO
    g=adyacencia_bloques{k}';
    nombres_bloques=cell(1,cant_bloques(k));
    for tr=1:cant_bloques(k)
        nombres_bloques{tr} = ['Bloque ' num2str(tr)];
    end
    grafos_bloques{k}=digraph(g(1,:),g(2,:));
    grafos_bloques{k}.Nodes.Name = nombres_bloques';
end

%%
mejores_tele_acoples=cell(cant_mejores_FO,1);     %Para 1 2 y 3 teleacoples de los 5 mejores
for k=1:cant_mejores_FO
    mejores_tele_acoples{k}=cell(2,1);
    mejores_tele_acoples{k}{1}=cell(1,cant_bloques_max,3);                   %Ubicacion y identificacion de los acoplamientos
    mejores_tele_acoples{k}{2}=zeros(3,1);                                  %donde almacenamos la potencia restablecida
    mejores_tele_acoples{k}{3}=ones(cant_bloques(k),cant_bloques(k),3);     %Matriz de estados de los bloques
end
for k=1:cant_mejores_FO
    [combinaciones,~]=size(cromo_acoples{k});   %cantidad de combinaciones de los acoples
    con_acople=find(~cellfun('isempty', alimentadores_bloques(k, :))); %Indica los bloques con alimentadores
    
    for d=1:combinaciones
        alimentadores=alimentadores_bloques;    %alimentadores por bloques
        matriz_de_estados_bloques=ones(cant_bloques(k),cant_bloques(k));
        carga_restablecida=0;
        acoples_considerados=con_acople(cromo_acoples{k}(d,:)==1); %De todos los bloques con acoples disponibles consideramos solo estos
        acoples_no_consiredados=con_acople(cromo_acoples{k}(d,:)==0); %acoples a no ser utilizados
        for e=1:length(acoples_no_consiredados)
            alimentadores{k,acoples_no_consiredados(e)}=[];  %eliminamos los acoples que no se consideran en esa ocacion
        end
        
        if length(acoples_considerados)==1 %siempre seleccionamos el alimentador con la carga maxima posible
            
            %verificamos que el acople sustente el propio
            num_alim=length(alimentadores{k,acoples_considerados}(:,1)); %cantidad de alimentadores
            mejor=0;
            mejor_id=[];
            for alim=1:num_alim
                Potencia_del_alimentador=demanda_asumible{strcmp(demanda_asumible(:,1),alimentadores{k,acoples_considerados}(alim,:)),2}; %potencia asumible por el alimentador
                if Potencia_del_alimentador >= mejor
                     mejor=Potencia_del_alimentador;
                     mejor_id=alim;
                end
            end
            %Dejamos solo la mejor opcion
            guardar=alimentadores{k,acoples_considerados}(mejor_id,:);
            alimentadores{k,acoples_considerados}(2:end,:)=[];
            alimentadores{k,acoples_considerados}(1,:)=guardar;
            
        else %cantidad de bloques con acoples mayor a 1
            %vamos a eliminar los alimentadores que se repitan en otros bloques siempre y cuando se tenga por lo menos 1
            for b=1:length(acoples_considerados)
                for b2=1:length(acoples_considerados)
                    if b2~=b
                        for alim=length(alimentadores{k,acoples_considerados(b)}(:,1)):-1:1
                            if ismember(alimentadores{k,acoples_considerados(b2)},alimentadores{k,acoples_considerados(b)}(alim,:),'rows') %Me da un true si ese alimentador existe en el otro bloque                                
                                if length(alimentadores{k,acoples_considerados(b)}(:,1)) > 1
                                    alimentadores{k,acoples_considerados(b)}(alim,:)=[];
                                end
                            end
                        end
                    end
                end
            end
            
            %Si siguen quedando mas de uno (osea son unicos de ese bloque), nos quedamos con el de mayor potencia
            for b=1:length(acoples_considerados)
                mejor=0;
                mejor_id=[];
                for alim=1:length(alimentadores{k,acoples_considerados(b)}(:,1))
                    Potencia_del_alimentador=demanda_asumible{strcmp(demanda_asumible(:,1),alimentadores{k,acoples_considerados(b)}(alim,:)),2}; %potencia asumible por el alimentador
                    if Potencia_del_alimentador >= mejor
                        mejor=Potencia_del_alimentador;
                        mejor_id=alim;
                    end
                end
                %Dejamos solo la mejor opcion
                guardar=alimentadores{k,acoples_considerados(b)}(mejor_id,:);
                alimentadores{k,acoples_considerados(b)}(2:end,:)=[];
                alimentadores{k,acoples_considerados(b)}(1,:)=guardar;
            end
        end
        
        for falla=1:cant_bloques(k)    %Hace fallar cada bloque
            potencias_de_alim=demanda_asumible;
            bloques_afectados=bfsearch(grafos_bloques{k},falla);
            bloques_salvados=[];
            %matriz de estados del bloque
            total_de_bloques=1:cant_bloques(k);
            bloques_no_afectados=total_de_bloques(~ismember(total_de_bloques,bloques_afectados));
            matriz_de_estados_bloques(falla,bloques_no_afectados)=0;
            
            for bi=2:length(bloques_afectados) %comenzamos del 2do bloque afectado ya que el primero posee la falla y es irrecuperable
                if any(ismember(acoples_considerados,bloques_afectados(bi))) %nos detenemos a analizar si el bloque posee acoples

                    %verificamos que el acople sustente el propio
                    Potencia_acumulada=carga_en_bloques(k,bloques_afectados(bi)); %carga en el bloque con acople
                    Potencia_del_alimentador=potencias_de_alim{strcmp(potencias_de_alim(:,1),alimentadores{k,bloques_afectados(bi)}),2}; %potencia asumible por el alimentador
                    estado= Potencia_del_alimentador > Potencia_acumulada; %si es verdadero puede sustentar el alimentador
                    
                    %aguas arriba
                    aguas_arriba=predecessors(grafos_bloques{k},bloques_afectados(bi)); %Siempre hay un solo sucesor (radial)
                    Potencia_acumulada1=0;
                    estado1=false;
                    if aguas_arriba~=1 && ~any(acoples_considerados==aguas_arriba)  %No 1er bloque, No bloque con reconectador, No bloque con falla, No bloque ya salvado por otro alimentador
                        if aguas_arriba~=falla && isempty(find(bloques_salvados==aguas_arriba, 1)) && estado
                            Potencia_acumulada1=Potencia_acumulada + carga_en_bloques(k,aguas_arriba);
                            estado1=Potencia_del_alimentador > Potencia_acumulada1; %si es verdadero puede sustentar un bloque mas
                        end
                    end
                    
                    %aguas abajo
                    aguas_abajo=successors(grafos_bloques{k},bloques_afectados(bi));
                    Potencia_acumulada2=zeros(1,length(aguas_abajo));
                    estado2=false(1,length(aguas_abajo));
                    for baa=1:length(aguas_abajo)   %Cada bloque aguas abajo
                        if isempty(find(acoples_considerados==aguas_abajo(baa), 1)) && isempty(find(bloques_salvados==aguas_abajo(baa), 1))  %El bloque aguas abajo no debe tener propio tele acople
                            if estado
                                Potencia_acumulada2(baa)=Potencia_acumulada + carga_en_bloques(k,aguas_abajo(baa));
                                estado2(baa)=Potencia_del_alimentador > Potencia_acumulada2(baa); %Si es verdadero puede soportar 2 bloques
                            end
                        end
                    end
                    
                    %% seleccionamos el bloque de mayor carga posible
                    if estado1==false && isempty(find(estado2, 1))   %Si no puede soportar nungun bloque ademas de si mismo
                      %Eliminamos o mantenemos el alimentador? NO
                      if estado
                          matriz_de_estados_bloques(falla,bloques_afectados(bi))=0; %Para la matriz de estados
                          carga_restablecida = carga_restablecida + Potencia_acumulada; %sustraemos la energia no suministrada
                          potencias_de_alim{strcmp(potencias_de_alim(:,1),alimentadores{k,bloques_afectados(bi)}),2}= Potencia_del_alimentador - Potencia_acumulada;  %Le quitamos la potencia consumida al alimentador                
                      end
                      
                    %% En el caso de que existan bloques adyacentes para alimentar
                    else
                        matriz_de_estados_bloques(falla,bloques_afectados(bi))=0; %Para la matriz de estados
                        
                        %% Seleccion del bloque adacente de mayor carga posible si fuera posible alimentarlo
                        mejor=0;  
                        mejor_id=[];
                        
                        %verificamos si se puede alimentar bloques aguas arriba
                        if estado1==true %Si hay un 1 va a guardar como la mejor opcion temporalmente
                            mejor=Potencia_acumulada1;
                            mejor_id=0;
                        end
                        
                        %verificamos si se puede alimentar bloques aguas abajo
                        for baa=1:length(Potencia_acumulada2)
                            if ~isempty(find(estado2(baa), 1))  %Si soporta el bloque lo guardamos
                                if Potencia_acumulada2(baa) > mejor
                                    mejor=Potencia_acumulada2(baa);
                                    mejor_id=baa;
                                end
                            end
                        end
                        
                        %% Guardamos los bloques energizados
                        if mejor_id==0 %Si el mejor bloque adyacente es la de aguas arriba
                            bloques_salvados=[bloques_salvados,aguas_arriba];
                            carga_restablecida = carga_restablecida + Potencia_acumulada1;
                            potencias_de_alim{strcmp(potencias_de_alim(:,1),alimentadores{k,bloques_afectados(bi)}),2}= Potencia_del_alimentador - Potencia_acumulada1;  %Le quitamos la potencia consumida al alimentador
                            alimentadores{k,aguas_arriba}=bloques_afectados(bi);
                            matriz_de_estados_bloques(falla,aguas_arriba)=0; %Para la matriz de estados
                            
                        else % Si el mejor bloque es uno de los aguas abajo
                            bloques_salvados=[bloques_salvados,aguas_abajo(mejor_id)];
                            carga_restablecida = carga_restablecida + Potencia_acumulada2(mejor_id);
                            potencias_de_alim{strcmp(potencias_de_alim(:,1),alimentadores{k,bloques_afectados(bi)}),2}= Potencia_del_alimentador - Potencia_acumulada2(mejor_id);  %Le quitamos la potencia consumida al alimentador
                            alimentadores{k,aguas_abajo(mejor_id)}=bloques_afectados(bi);
                            matriz_de_estados_bloques(falla,aguas_abajo(mejor_id))=0; %Para la matriz de estados
                        end
                    end
                end
            end
        end
        
        %ELiminamos los alimentadores inservibles
        for ssd=1:cant_bloques_max
            if any(ismember(acoples_considerados,ssd)) %nos detenemos a analizar si el bloque posee acoples
                %verificamos que el acople sustente el propio
                 Potencia_acumulada=carga_en_bloques(k,ssd); %carga en el bloque con acople
                 Potencia_del_alimentador=potencias_de_alim{strcmp(potencias_de_alim(:,1),alimentadores{k,ssd}),2}; %potencia asumible por el alimentador
                 estado= Potencia_del_alimentador > Potencia_acumulada; %si es verdadero puede sustentar el alimentador    

                 if ~estado %Si no se soporta a si mismo lo eliminamos
                     alimentadores{k,ssd}=[];
                 end
            end
        end
        
        %Guardamos los mejores resultados de acuerdo al que mas Energia Recuperada posea
        if length(acoples_considerados)==1
            if carga_restablecida > mejores_tele_acoples{k}{2}(1)
                mejores_tele_acoples{k}{1}(:,:,1)=alimentadores(k,:);
                mejores_tele_acoples{k}{2}(1)=carga_restablecida;
                mejores_tele_acoples{k}{3}(:,:,1)=matriz_de_estados_bloques;
            end
            
        elseif length(acoples_considerados)==2
            if carga_restablecida > mejores_tele_acoples{k}{2}(2)
                mejores_tele_acoples{k}{1}(:,:,2)=alimentadores(k,:);
                mejores_tele_acoples{k}{2}(2)=carga_restablecida;
                mejores_tele_acoples{k}{3}(:,:,2)=matriz_de_estados_bloques;
            end
        else
            if carga_restablecida > mejores_tele_acoples{k}{2}(3)
                mejores_tele_acoples{k}{1}(:,:,3)=alimentadores(k,:);
                mejores_tele_acoples{k}{2}(3)=carga_restablecida;
                mejores_tele_acoples{k}{3}(:,:,3)=matriz_de_estados_bloques;
            end 
        end
    end
end
end