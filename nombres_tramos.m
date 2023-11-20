function nombres_tramos=nombres_tramos(A) % Funcion que recibe una matriz A y nombra los tramos.
% A: Matriz Adyacencia cargado en Excel
Ntr=length(A(1,:)); %nro de Tramos.
%% Crear un array tipo cell para cargar nombre de tramos
nombres_tramos = cell(1, Ntr); % Inicializar el cell array
%% Llenar el cell array con nombres de tramos
    for i = 1:Ntr
        nombres_tramos{i} = ['Tramo ' num2str(i)];
    end
end