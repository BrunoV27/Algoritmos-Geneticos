clc
clear
close all
% mi sistema representa un alimentador de distribucion ITG 8
%% Parametros de control del AG
N=1;                      %Cantidad maxima de reconectadores
Npob=8;                  %cantidad de cromosomas a ser analizado
Npob=ceil(Npob/4)*4;      %Necesariamente necesitamos que Npob sea multiplo de 4 ya que se debe dividir dos veces entre 2
Xmut=0.1;                 %tasa de mutacion
V=20;                     %Velocidad promedio de cuadrilla en km/h
iteraciones=100;          %cantidad de iteraciones
precio_un = 14310;     % Costo de Inversión un reconectador
Ce = 400;                 % Costo de energía Gs/kWh 13190 o 400
Nro_max_acoples=1;      %Cantidad maxima de acoplamientos que se desea encontrar en el alimentador (Max 3)
recos=[]; %Insertar posiciones donde ya hay reconectadores dentro de la troncal

%% Extraccion de datos del excel
Ady=readmatrix('ITG8.xlsx','sheet','Grafos','Range','B3:Q18') %Matriz de Adyacencia
tasa_falla=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','F7:F22') %vector que contiene los lambda "i"
tiempo_reparo=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','H7:H22') % vector que contiene los tiempo de reparo
tiempo_seccionamiento=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','G7:G22') % vector que contiene los tiempo de seccionamiento
longitudes_tramos=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','C7:C22') % vector que contiene las longitudes de tramos
Li=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','J7:J22')  % Potencia Li (kW)
pesos_tramos=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','K7:K22')
dispositivos=readmatrix('ITG8.xlsx','sheet','Datos Iniciales','Range','M7:M22')    %Indica los tramos con IC, SC y SF del alimentador
acoplamientos=readcell('ITG8.xlsx','sheet','Datos Iniciales','Range','N7:P22')    %Indica los puntos de acoplamientos y cantidad de acoplamientos en cada tramo
demanda_asumible=readcell('DemandaMaximaRegistrada.xlsx','sheet','Demandas Maximas','Range','B21:C34')

%% Datos Extraidos o Arbitrarios
Ntr=length(Ady(1,:));               %Nro de tramos
cant_ramales=sum(dispositivos==2);  %tramos con seccionadores fusibles

%% Crear el digrafo
nombres_tramos=nombrar_tramos(Ady,cant_ramales);
grafo1=digraph(Ady,nombres_tramos); % representacion del sistema energizado

%% Calculos de Tiempos
[Tci, Tsi, Tfi, TTi, TRi]=tiempos(tiempo_seccionamiento,tiempo_reparo,longitudes_tramos,Ntr,grafo1,cant_ramales,V);   %calculo de tiempos para fallas
%% Sistema inicial
cromo_arbi=zeros(1,Ntr);        %Creamos un cromosoma arbitrario
cromo_arbi(1,1)=1;              %siempre un interruptor en la cabecera
cromo_arbi(recos)=1;            %se insertan los reconectadores arbitrarios

%% Crear un vector binario para representar la presencia o ausencia de reconectadores en cada nodo
nodos_con_reconectador=poblacion_aleatoria(Npob,Ntr,N,cant_ramales);

TABLA1=zeros(5,iteraciones);
TABLA=zeros(5,iteraciones);
mejores_5_FO=cell(1,3);    % 1.poblacion   2.FO   3.Mejor cromosoma de cada iteracion

%Guardar los menores valores obtenidos
pob_menor=zeros(Npob,Ntr);
FO_menor_poblacion=zeros(1,Npob);

h=waitbar(0, 'Procesando...');
%% Ejecucion del AG
for ag=1:iteraciones
    waitbar(ag/iteraciones,h,sprintf('Procesando... %d%%',round(ag/iteraciones*100)));
    
    %% es un array que contiene la cantidad de matrices de estados para cada cromosoma
    E=MatrizEstados(Npob,Ntr,cant_ramales,nodos_con_reconectador,grafo1);

    %% Crear Matrices necesarias relacionadas a las fallas en el alimentador
    [Matriz_tasa_falla, Matriz_tiempo_interrupcion, Matriz_indisponibilidad, Matriz_kvai]=matrices(Npob,Ntr,cant_ramales,E,tasa_falla,Tsi,TTi,TRi,Ady,Li,grafo1);
    
    %% Indisponibilidad anual e indice de confiabilidad FMIK
    Ui=sum(Matriz_indisponibilidad,1);      %crea un vector con la sumatoria de las columnas.
    FMIK=sum(Matriz_kvai.*Matriz_tasa_falla,[1 2])/sum(Li);    %Contiene el kWfsi por cada elemento de la poblacion
    DEP=sum(Matriz_kvai.*Matriz_indisponibilidad,[1 2])/sum(Li); %DEP por cada individuo
    
    %% Calculo de la Funcion objetivo para cada cromosoma, que sera minimizada
    [FO,ENS,A,B,C,D,d]=Funcion_Objetivo(precio_un,Ce,nodos_con_reconectador,Npob,Li,Ui,pesos_tramos,DEP,FMIK,grafo1,Ntr,cant_ramales);
    
    %% Guarda las mejores opciones posibles dentro de las iteraciones
    poblacion=nodos_con_reconectador;
    
    [~,indices_ordenados]=sort(FO);
    FO=FO(indices_ordenados);           %ordenamos los cromosomas de menor a mayor FO
    poblacion=poblacion(indices_ordenados,:);
    ENS=ENS(indices_ordenados);
    A=A(indices_ordenados);
    B=B(indices_ordenados);
    C=C(indices_ordenados);
    D=D(indices_ordenados);
    DEP=DEP(indices_ordenados);
    FMIK=FMIK(indices_ordenados);
    
    if ag==1
        mejores_5_FO{1,1}(1,:)=poblacion(1,:);
        mejores_5_FO{1,2}(1,1)=FO(1);   
        mejores_5_FO{1,2}(1,2)=A(1);
        mejores_5_FO{1,2}(1,3)=B(1);
        mejores_5_FO{1,2}(1,4)=C(1);
        mejores_5_FO{1,2}(1,5)=D(1);
        u=1;
        %Para la comparacion de la poblacion actual con la ultima
        poblacion_inicial=poblacion;    
        FO_inicial=FO;
        for i=2:Npob
            if ~any(ismember(mejores_5_FO{1,1},poblacion(i,:),'rows'))
                u=u+1;
                mejores_5_FO{1,1}(u,:)=poblacion(i,:);
                mejores_5_FO{1,2}(u,1)=FO(i);
                mejores_5_FO{1,2}(u,2)=A(i);
                mejores_5_FO{1,2}(u,3)=B(i);
                mejores_5_FO{1,2}(u,4)=C(i);
                mejores_5_FO{1,2}(u,5)=D(i);
            end
            
            if u==5
                break
            end
        end
    else
        u=[];
        for i=1:Npob
            if ~any(ismember(mejores_5_FO{1,1},poblacion(i,:),'rows'))
                u=i;
                break
            end
        end
        if FO(u) < mejores_5_FO{1,2}(5,1)
            mejores_5_FO{1,2}(5,1)=FO(u);                 %reemplaza el peor de los 5 mejores por el mejor de la poblacion
            mejores_5_FO{1,2}(5,2)=A(u);
            mejores_5_FO{1,2}(5,3)=B(u);
            mejores_5_FO{1,2}(5,4)=C(u);
            mejores_5_FO{1,2}(5,5)=D(u);
            mejores_5_FO{1,1}(5,:)=poblacion(u,:);
            
            [~,indices_ordenados]=sort(mejores_5_FO{1,2}(:,1));
            mejores_5_FO{1,2}=mejores_5_FO{1,2}(indices_ordenados,:);    %ordenamos los cromosomas de menor a mayor FO
            mejores_5_FO{1,1}=mejores_5_FO{1,1}(indices_ordenados,:);
            disp('SI');
        end
    end
      
    %%
    if ag==1
        FO_menor_poblacion(1,:)=FO(1,:);
        pob_menor=poblacion;
        padres_menor=seleccion(FO,Npob);
        FO_menor=min(FO_menor_poblacion);
        ENSmin=ENS;
    elseif min(FO(1,:)) < min(FO_menor_poblacion(1,:))
        FO_menor_poblacion(1,:)=FO(1,:);
        pob_menor=poblacion;
        padres_menor=seleccion(FO,Npob);
        FO_menor=min(FO);
        ENSmin=ENS;
    end
    %% Operadores de seleccion, cruce y mutacion
    padres_id=seleccion(FO,Npob);
    
    pob_1=cruce(poblacion,padres_id,Ntr,Npob,cant_ramales,N);
    
    pob_2=mutacion(poblacion,pob_1,Ntr,Npob,cant_ramales,Xmut,N);
    
    nodos_con_reconectador=pob_2;   %empieza de nuevo el ciclo
    
    %Guarda los datos del mejor cromosoma en cada iteracion
    TABLA1(1:5,ag)=mejores_5_FO{1,2}(:,1);
    TABLA(1,ag)=A(1);
    TABLA(2,ag)=B(1);
    TABLA(3,ag)=C(1);
    TABLA(4,ag)=D(1);
    TABLA(5,ag)=FO(1);  %mejor por cada iteracion
end
%% Calculos para el cromosoma arbitrario
M1=MatrizEstados(1,Ntr,cant_ramales,cromo_arbi,grafo1);
[Matriz_tasa_falla1, Matriz_tiempo_interrupcion1, Matriz_indisponibilidad1, Matriz_kvai1]=matrices(1,Ntr,cant_ramales,M1,tasa_falla,Tsi,TTi,TRi,Ady,Li,grafo1);
Ui1=sum(Matriz_indisponibilidad1,1);      %crea un vector con la sumatoria de las columnas.
FMIK1=sum(Matriz_kvai1.*Matriz_tasa_falla1,[1 2])/sum(Li);    %Contiene el kWfsi por cada elemento de la poblacion
DEP1=sum(Matriz_kvai1.*Matriz_indisponibilidad1,[1 2])/sum(Li); %DEP por cada individuo
[FO1,ENS1,A1,B1,C1,D1]=Funcion_Objetivo(precio_un,Ce,cromo_arbi,1,Li,Ui1,pesos_tramos,DEP1,FMIK1,grafo1,Ntr,cant_ramales);
%Configuracion de los acoplamientos para sistema inicial
if ~isempty(recos) %Si el cromosoma arbitrario no posee reconectadores por defecto, no hace este calculo
    [bloques1, carga_en_bloques1]=bloques_de_carga_1(grafo1,cromo_arbi,Ntr,cant_ramales,Li);
    [adyacencia_bloques1, alimentadores_bloques1, cromo_acoples1, grafos_bloques1, mejores_tele_acoples1]=configuracion_acoples(grafo1,acoplamientos,bloques1,carga_en_bloques1,demanda_asumible);

    M_acoples1=MatrizEstados(1,Ntr,cant_ramales,cromo_arbi,grafo1); %Esto unicamente recalcula la matriz de estados de los mejores cromosomas.sin LLaves NA
    [Matriz_tasa_falla_acoples1, Matriz_tiempo_interrupcion_acoples1, Matriz_indisponibilidad_acoples1, Matriz_kvai_acoples1]=matrices_acoples(1,Ntr,cant_ramales,M_acoples1,tasa_falla,Tsi,TTi,TRi,Ady,Li,grafo1,mejores_tele_acoples1,bloques1);
    Ui_acoples1=sum(Matriz_indisponibilidad_acoples1,1);      %crea un vector con la sumatoria de las columnas.
    FMIK_acoples1=sum(Matriz_kvai_acoples1.*Matriz_tasa_falla_acoples1,[1 2])/sum(Li);
    DEP_acoples1=sum(Matriz_kvai_acoples1.*Matriz_indisponibilidad_acoples1,[1 2])/sum(Li); %DEP por cada individuo
    ENS_acoples1=ens_acoplamientos(1,Li,Ui_acoples1);
end

%% Calculamos la configuracion de los acoplamientos
[bloques, carga_en_bloques]=bloques_de_carga(grafo1,mejores_5_FO,Ntr,cant_ramales,Li);
[adyacencia_bloques, alimentadores_bloques, cromo_acoples, grafos_bloques, mejores_tele_acoples]=configuracion_acoples(grafo1,acoplamientos,bloques,carga_en_bloques,demanda_asumible);

M_acoples=MatrizEstados(5,Ntr,cant_ramales,mejores_5_FO{1},grafo1); %Esto unicamente recalcula la matriz de estados de los mejores cromosomas.sin LLaves NA
[Matriz_tasa_falla_acoples, Matriz_tiempo_interrupcion_acoples, Matriz_indisponibilidad_acoples, Matriz_kvai_acoples]=matrices_acoples(5,Ntr,cant_ramales,M_acoples,tasa_falla,Tsi,TTi,TRi,Ady,Li,grafo1,mejores_tele_acoples,bloques);
Ui_acoples=sum(Matriz_indisponibilidad_acoples,1);      %crea un vector con la sumatoria de las columnas.
FMIK_acoples=sum(Matriz_kvai_acoples.*Matriz_tasa_falla_acoples,[1 2])/sum(Li);
DEP_acoples=sum(Matriz_kvai_acoples.*Matriz_indisponibilidad_acoples,[1 2])/sum(Li); %DEP por cada individuo
ENS_acoples=ens_acoplamientos(5,Li,Ui_acoples);

close(h);
%% Graficos
%alimentadores y sus reconectadores
for k=1:5
    figure(k);
    colores = repmat([0 0 1], Ntr, 1); % Inicializar todos los nodos con un color predeterminado (azul)
    colores(Ntr-cant_ramales+1:Ntr, :) = repmat([0 0 0], length(Ntr-cant_ramales+1:Ntr), 1); % Asignar un color diferente (rojo) a los nodos específicos
   
    m=find(mejores_5_FO{1,1}(k,:)); %localizamos la posicion de las LlT
    m(1)=[];
    colores(m, :) = repmat([1 0 0], length(m), 1);  %Las marcamos
    
    subplot('Position', [0.01, 0.1, 0.49, 0.85]);  % Primer gráfico
    plot(grafo1,'NodeColor',colores,'EdgeColor','g');
    title(num2str((k)', 'Grafo Opción %d'));
    texto_pie = sprintf('FO = %d   ||   ENS = %d   ||   Llaves NC = %d \n \n DEP = %d   ||   FMIK = %d', mejores_5_FO{1,2}(k,1), mejores_5_FO{1,2}(k,2), length(m), mejores_5_FO{1,2}(k,5)/d, mejores_5_FO{1,2}(k,3)/d);
    xlabel(texto_pie, 'Interpreter', 'none');
    
    aux=1;
    for w=2:Nro_max_acoples
        if mejores_tele_acoples{k}{2}(w) > 0
            aux=w;
        end
    end
    subplot('Position', [0.50, 0.1, 0.49, 0.85]);  % Segundo gráfico
    hh=plot(grafos_bloques{k});
    title('Grafo de Bloques');
    x = hh.XData;
    y = hh.YData;
    % Ajustar las coordenadas de las etiquetas para centrarlas sobre los nodos
    offset = 0.05; % Ajusta este valor según sea necesario
    num_NA=0;
    [~,cant_bloques]=size(mejores_tele_acoples{k}{1}(1,:,aux));
    for b = 1:cant_bloques
        % Colocar las etiquetas de las propiedades a la izquierda
        text(x(b) - offset, y(b), mejores_tele_acoples{k}{1}(1,b,aux), 'HorizontalAlignment', 'right');
        if ~isnumeric(mejores_tele_acoples{k}{1}{1,b,aux})
            num_NA=num_NA+1;
        end
    end
    texto_pie = sprintf('ENS = %d   ||   Llaves NA= %d \n \n DEP = %d   ||   FMIK = %d', ENS_acoples(1,k,aux),num_NA, DEP_acoples(1,1,k,aux), FMIK_acoples(1,1,k,aux));
    xlabel(texto_pie, 'Interpreter', 'none');
    
    
    %Representacion de bloques
    figure(30+k);
    colores = repmat([0 0 1], Ntr, 1); % Inicializar todos los nodos con un color predeterminado (azul)
    colores_bloques = repmat([0 0 1], cant_bloques, 1); % Inicializar todos los nodos con un color predeterminado (azul)
    for b=1:cant_bloques
        binario = dec2bin(b);
        binario = sprintf('%03s', binario);
        colores_bloques(b,:)=str2num(binario')';
        for h=1:length(bloques{k,b})
            colores(bloques{k,b}, :) = repmat(str2num(binario')', length(bloques{k,b}), 1); % Asignar un color diferente (rojo) a los nodos específicos
        end
    end    
    subplot('Position', [0.01, 0.1, 0.49, 0.85]);  % Primer gráfico
    plot(grafo1,'NodeColor',colores,'EdgeColor','k');
    title(num2str((k)', 'Grafo Opción %d'));
    texto_pie = sprintf('FO = %d   ||   ENS = %d   ||   Llaves NC = %d \n \n DEP = %d   ||   FMIK = %d', mejores_5_FO{1,2}(k,1), mejores_5_FO{1,2}(k,2), length(m), mejores_5_FO{1,2}(k,5)/d, mejores_5_FO{1,2}(k,3)/d);
    xlabel(texto_pie, 'Interpreter', 'none');
    
    aux=1;
    for w=2:Nro_max_acoples
        if mejores_tele_acoples{k}{2}(w) > 0
            aux=w;
        end
    end
    subplot('Position', [0.50, 0.1, 0.49, 0.85]);  % Segundo gráfico
    hh=plot(grafos_bloques{k},'NodeColor',colores_bloques,'EdgeColor','k');
    title('Grafo de Bloques');
    x = hh.XData;
    y = hh.YData;
    % Ajustar las coordenadas de las etiquetas para centrarlas sobre los nodos
    offset = 0.05; % Ajusta este valor según sea necesario
    num_NA=0;
    [~,cant_bloques]=size(mejores_tele_acoples{k}{1}(1,:,aux));
    for b = 1:cant_bloques
        % Colocar las etiquetas de las propiedades a la izquierda
        text(x(b) - offset, y(b), mejores_tele_acoples{k}{1}(1,b,aux), 'HorizontalAlignment', 'right');
        
        if ~isnumeric(mejores_tele_acoples{k}{1}{1,b,aux})
            num_NA=num_NA+1;
        end
    end
    texto_pie = sprintf('ENS = %d   ||   Llaves NA= %d \n \n DEP = %d   ||   FMIK = %d', ENS_acoples(1,k,aux),num_NA, DEP_acoples(1,1,k,aux), FMIK_acoples(1,1,k,aux));
    xlabel(texto_pie, 'Interpreter', 'none');
    
   
    %Dibuja las barras con y sin llaves
    figure(20+k);
    bar(1:3,[ENS1, mejores_5_FO{1,2}(k,2), ENS_acoples(1,k,aux)]);
    xlabel('Configuracion Inicial   ||   Con Llaves Telecomandadas NC   ||   Con Llaves Telecomandadas NC y NA');
    ylabel('Energia No Suministrada');
    title(num2str((k)', 'Evolucion del cromosoma %d'));
end

figure(6);
hold on;
plot(1:iteraciones,TABLA(5,:),'LineWidth',2);
plot(1:iteraciones,TABLA(1,:),'LineWidth',2);
plot(1:iteraciones,TABLA(2,:),'LineWidth',2);
plot(1:iteraciones,TABLA(3,:),'LineWidth',2);
plot(1:iteraciones,TABLA(4,:),'LineWidth',2);
legend('FO','CENS', 'FMIK','Tramos Import','DEP');
xlabel('ITERACIONES');
ylabel('FO');
title('Mejor opcion para a lo largo de las iteraciones');
hold off;

figure(7);
plot(1:iteraciones,TABLA1);
xlabel('ITERACIONES');
ylabel('FO por individuo');
title('5 mejores a lo largo de la iteraciones');
legend(num2str((1:5)', 'Mejor opcion %d'));

figure(8);
hold on;
bar(1:2:2*Npob,FO_inicial);
bar(2:2:2*Npob+1,FO);
legend('Poblacion Inicial', 'Poblacion Final');
set(gca, 'YScale', 'log');
xlabel('POBLACIONES');
ylabel('FO de cada individuo');
title('Primera poblacion vs Ultima poblacion');
hold off;

figure(9);
plot(1:iteraciones,TABLA(5,:));
xlabel('ITERACIONES');
ylabel('FO');
title('Mejor opcion para a lo largo de las iteraciones (SOLO FO)');

figure(10);
colores = repmat([0 0 1], Ntr, 1); % Inicializar todos los nodos con un color predeterminado (azul)
colores(Ntr-cant_ramales+1:Ntr, :) = repmat([0 0 0], length(Ntr-cant_ramales+1:Ntr), 1); % Asignar un color diferente (rojo) a los nodos con fusibles
m1=find(cromo_arbi);    %localizamos la posicion de las LlT
m1(1)=[];               %eliminamos el interruptor de cabecera
colores(m1, :) = repmat([1 0 0], length(m1), 1);  %Las marcamos
plot(grafo1,'NodeColor',colores,'EdgeColor','g');
title('Grafo del sistema inicial');
texto_pie = sprintf('FO = %d     ENS = %d     Llaves NC = %d     DEP = %d', FO1, ENS1, length(m1), DEP1);
xlabel(texto_pie, 'Interpreter', 'none');

disp('Mejores 5 opciones');
mejores_5_FO{1,1}
mejores_5_FO{1,2}

disp('Cromosoma Arbitrario y su FO');
cromo_arbi
FO1
% Impresion de mejores cromosomas y sus FO
Po=zeros(5,Ntr);
for i=1:5
    for j=1:Ntr
    if j==1
        Po(i,j)=1;
    else
    Po(i,j)=0;
    end
    end
end
mejores_5_cromosomas = mejores_5_FO{1,1}-Po
mejores_5_F_O = mejores_5_FO{1,2}(:,1)
%
if ~isempty(recos)
    figure(11);
    colores = repmat([0 0 1], Ntr, 1); % Inicializar todos los nodos con un color predeterminado (azul)
    colores(Ntr-cant_ramales+1:Ntr, :) = repmat([0 0 0], length(Ntr-cant_ramales+1:Ntr), 1); % Asignar un color diferente (rojo) a los nodos con fusibles
    m1=find(cromo_arbi);    %localizamos la posicion de las LlT
    m1(1)=[];               %eliminamos el interruptor de cabecera
    colores(m1, :) = repmat([1 0 0], length(m1), 1);  %Las marcamos
    subplot('Position', [0.01, 0.1, 0.49, 0.85]);  % Primer gráfico
    plot(grafo1,'NodeColor',colores,'EdgeColor','g');
    title('Grafo del sistema inicial');
    texto_pie = sprintf('FO = %d   ||   ENS = %d   ||   Llaves NC = %d \n \n DEP = %d   ||   FMIK = %d', FO1, ENS1, length(m1), DEP1, FMIK1);
    xlabel(texto_pie, 'Interpreter', 'none');    
    aux=1;
    for w=2:Nro_max_acoples
        if mejores_tele_acoples1{1}{2}(w) > 0
            aux=w;
        end
    end
    subplot('Position', [0.50, 0.1, 0.49, 0.85]);  % Segundo gráfico
    hh=plot(grafos_bloques1{1});
    title('Grafo de Bloques');
    x = hh.XData;
    y = hh.YData;
    % Ajustar las coordenadas de las etiquetas para centrarlas sobre los nodos
    offset = 0.05; % Ajusta este valor según sea necesario
    num_NA=0;
    [~,cant_bloques1]=size(mejores_tele_acoples1{1}{1}(1,:,aux));
    for b = 1:cant_bloques1
        % Colocar las etiquetas de las propiedades a la izquierda
        text(x(b) - offset, y(b), mejores_tele_acoples1{1}{1}(1,b,aux), 'HorizontalAlignment', 'right');

        if ~isnumeric(mejores_tele_acoples1{1}{1}{1,b,aux})
            num_NA=num_NA+1;
        end
    end
    texto_pie = sprintf('ENS = %d   ||   Llaves NA= %d \n \n DEP = %d   ||   FMIK = %d', ENS_acoples1(1,1,aux),num_NA, DEP_acoples1(1,1,1,aux), FMIK_acoples1(1,1,1,aux));
    xlabel(texto_pie, 'Interpreter', 'none');
end