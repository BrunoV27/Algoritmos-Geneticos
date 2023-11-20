function ME=MatrizEstados(Npob,Ntr,cant_ramales,nodos_con_reconectador,grafo1)
ME=zeros(Ntr,Ntr,Npob);
E=zeros(Ntr);
for k=1:Npob
    %% Definicion de categorías según halla o no un reconectador
    categoria_nodos=nodos_con_reconectador(k,:);    %cromosoma a ser analizado
    
    %% Nodo con falla en el troncal
    for j=1:Ntr-cant_ramales %voy con for de 1 a "n" cantidad de tramos definidos       
        nodo_falla =j; %ubicacion en donde se desarrolla la falla

        %% Implementar DFS inversa
        stack = []; % Inicializar una pila vacía
        stack = [stack, nodo_falla]; % Agregar el nodo de falla a la pila
        
        %% Inicializar una variable para el nodo con reconectador más cercano (inicialmente vacío)
        nodo_mas_cercano = [];
        while ~isempty(stack)
            nodo_actual = stack(end); % Obtener el último nodo de la pila
            stack = stack(1:end-1); % Eliminar el último nodo de la pila
            if categoria_nodos(nodo_actual) == 1
                nodo_mas_cercano=nodo_actual; 
            % Si encuentras un nodo con reconectador, detiene la búsqueda y almacena el nodo
                break;
            else
            % Si no es un nodo con reconectador, continúa la búsqueda en profundidad inversa
                predecesores=predecessors(grafo1, nodo_actual);
                stack=[stack, predecesores];
            end
        end

        if ~isempty(nodo_mas_cercano)
            %disp(['Activó el reconectador del ' nombres_tramos{nodo_mas_cercano} '.']);
        end
        
        %Realizar una búsqueda en anchura desde el nodo con reconectador
        nodos_afectados = bfsearch(grafo1, nodo_mas_cercano); % busca los nodos afectados por la apertura del reconectador aguas abajo
        
        % Inicializar un vector de ceros para indicar si un nodo fue afectado o no
        nodos_afectados_vector =zeros(1, numnodes(grafo1));
        
        % nodos_afectados contiene los índices de los nodos afectados
        for i = 1:length(nodos_afectados)
            nodo_afectado = nodos_afectados(i); % Obtener el índice del nodo afectado actual
            nodos_afectados_vector(nodo_afectado) = 1; % Configurar el valor en 1 en la posición correspondiente
        end
        E(j,:)=nodos_afectados_vector;  %se carga en la matriz de estados
    end
        %% Ramales con fusibles
        for j=Ntr-cant_ramales+1:Ntr
            %disp(['Activó el fusible del Tramo ' num2str(j) '.']);
            nodo_falla=j;
            nodos_afectados=bfsearch(grafo1,nodo_falla); % me idenfifica los nodos aguas abajo del nodo seleccionado
            nodos_afectados_vector =zeros(1, numnodes(grafo1));
            % nodos_afectados contiene los índices de los nodos afectados
            for i = 1:length(nodos_afectados)
                nodo_afectado = nodos_afectados(i); % Obtener el índice del nodo afectado actual
                nodos_afectados_vector(nodo_afectado) = 1; % Configurar el valor en 1 en la posición correspondiente
            end
        E(j,:)=nodos_afectados_vector;
        end
ME(:,:,k)=E; % guarda cada matriz de estado en una matriz tridimensional M 

end
end